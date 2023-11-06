//
//  ViewModel.swift
//  XCAChatGPT
//
//  Created by P on 2023-10-13.
//
import Foundation
import SwiftUI
import AVKit

class ViewModel: ObservableObject {
    var resetTimer: Timer?
    @Published var isInteractingWithModel = false {
        didSet {
            if isInteractingWithModel {
                startResetTimer()
            } else {
                resetTimer?.invalidate()
                resetTimer = nil
            }
        }
    }

    @Published var messages: [MessageRow] = []{
        didSet {
            print("Messages updated:", messages)
        }
    }
    @Published var isEndOfStream: Bool = false
    @Published var inputMessage: String = ""
    @Published var webSocketVM = WebSocketViewModel(url: Constants.webSocketURL)
    
    @Published var suggested_user_inputs: [String] = [
        "price of eth",
        "what's hot in crypto?",
        "vitalik.eth net worth",
        "ftx trial update",
        "best ETH lending rate on arbitrum",
        "ai-related cryptos with promise?"
    ]{   willSet {
        print("hit ", newValue)
        
    }
        didSet {
           
            if oldValue != suggested_user_inputs {
                print("Value changed from \(oldValue) to \(suggested_user_inputs)")
            }
        }
    }

//    private let api: ChatUAPI
    func clearChat() {
        messages.removeAll()
    }
    init() {
//        self.api = api
        self.webSocketVM.connect()
        
        Task {
                await self.fetchSuggestedQuestions(lastUserMessage: "", firstRun: true)
            }
//        await self.fetchSuggestedQuestions(lastUserMessage: "", firstRun: true)
        
        
    }
    
    @MainActor
    func sendTapped() async {
        let text = inputMessage
        //clear out current var inputMessage
        inputMessage = ""
        await send(text:text)
    }
    
    @MainActor
    func retry(message: MessageRow) async {
        // find index of message in array with message id, extract it from aaray and send again
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
            return
        }
        self.messages.remove(at:index)
        await send(text:message.sendText)
    }
    
    struct SuggestedInputsResponse: Codable {
        var suggested_user_inputs: [String]
    }
    
    func fetchSuggestedQuestions(lastUserMessage: String, firstRun: Bool =  false) async {
        let url = URL(string: Constants.httpUrlForSuggestedInputs)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let bodyData = ["text": lastUserMessage, "firstRun": firstRun] as [String : Any]
        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyData, options: [])
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            print("Received from server:", String(data: data, encoding: .utf8) ?? "invalid string data")
            let fetchedQuestionsResponse = try JSONDecoder().decode(SuggestedInputsResponse.self, from: data)
            DispatchQueue.main.async {
                print("fetched q's - ", fetchedQuestionsResponse.suggested_user_inputs)
                
                if firstRun {
                    if fetchedQuestionsResponse.suggested_user_inputs.count >= 3 {
                                            self.suggested_user_inputs[0] = fetchedQuestionsResponse.suggested_user_inputs[0]
                                            self.suggested_user_inputs[2] = fetchedQuestionsResponse.suggested_user_inputs[1]
                                            self.suggested_user_inputs[4] = fetchedQuestionsResponse.suggested_user_inputs[2]
                                        }
                }
                else {
                    
                    self.suggested_user_inputs = fetchedQuestionsResponse.suggested_user_inputs
                }
            }
        } catch {
            print("Error fetching questions:", error)
            isInteractingWithModel = false // reset here?
        }
    }
   
    @MainActor
    func addImageRow(isFromUser: Bool, imageUrl: String? = nil, imageData: Data? = nil) {
            let row = MessageRow(
                isFromUser: isFromUser,
                isInteractingwithModel: !isFromUser,
                sendImage: isFromUser ? "profile" : "langicon",
                sendText: "",
                responseImage: isFromUser ? "" : "langicon",
                responseText: ""
            )
            row.imageUrl = imageUrl
            row.imageData = imageData
            self.messages.append(row)
        }
    
    @MainActor
    private func send(text: String) async {
        isInteractingWithModel = true
        
        // Trim whitespaces and newline characters from both the text and suggested inputs
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if the text is a suggested input or off by 1 character
        let isSuggestedInput = suggested_user_inputs.contains {
            let trimmedSuggestion = $0.trimmingCharacters(in: .whitespacesAndNewlines)
            return isCloseMatch(input: trimmedText, suggestion: trimmedSuggestion)
        }

        // Construct the message object with the is_suggested_input property
        let webSocketMessage = WebSocketMessageOut(
            text: text,
            user_secret: "secret-boopalo",
            user_identifier: PersistentUserState.userIdentifier ?? "default_userid",
            msg_id: UUID().uuidString,
            is_suggested_input: isSuggestedInput // Add this property to your WebSocketMessageOut model
        )
        
        // Convert the message object to JSON and send
        do {
            let jsonData = try JSONEncoder().encode(webSocketMessage)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                webSocketVM.send(message: jsonString)
            }
        } catch {
            print("Failed to encode WebSocketMessage:", error)
        }
        
     
        // Initialize the message row for the outgoing (user) message
        let userMessageRow = MessageRow(
            isFromUser: true,
            isInteractingwithModel: false,
            sendImage: "profile",
            sendText: text,
            responseImage: "",
            responseText: ""
        )
        self.messages.append(userMessageRow)
        

        
        // Capture the current message index for later use (Lang's index)
       
        
        // Define the response handling mechanism
        // ONLY FOR TEXT !?
        
        
        webSocketVM.onImageReceived = { [weak self] (message: WebsocketMessageData) in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                
                // Ensure 'imageUrl' is taken from the 'message' object or some other source.
                let imageUrl : String = message.url ?? "profile.png" // Assuming `url` is a property in WebSocketMessageIn

                let langImageRow = MessageRow(
                    isFromUser: false,
                    isInteractingwithModel: false,
                    sendImage: "",
                    sendText: "",
                    responseImage: "",
                    responseText: "",
                    imageUrl: imageUrl
                )
                strongSelf.messages.append(langImageRow)
                let currentIndex = strongSelf.messages.count - 1
                
                if currentIndex < strongSelf.messages.count {
                    strongSelf.isInteractingWithModel = false
                    if let isEndOfStream = message.end_of_stream as? Bool, isEndOfStream {
                        strongSelf.messages[currentIndex].toggleInteractingWithModel(isInteracting: false)
                        strongSelf.isEndOfStream = isEndOfStream
                    }
                }
            }
        }
        
        var langMessageRow = MessageRow(
            isFromUser: false,
            isInteractingwithModel: true,
            sendImage: "langicon",
            sendText: "",
            responseImage: "langicon",
            responseText: ""
        )
        self.messages.append(langMessageRow)


      
        webSocketVM.onMessageReceived = { [weak self] message in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }

                // Initialize the message row for the Lang  response
//                strongSelf.messages.append(langMessageRow)
                
                self?.isInteractingWithModel = false
                
                let currentIndex = strongSelf.messages.count - 1
                if let strongSelf = self, currentIndex < strongSelf.messages.count {
//                    if message.message_type?.rawValue ?? "text" == "image" {
//                        if let imageUrl = message.url {
//                                strongSelf.messages[currentIndex].imageUrl = imageUrl
//                            }
//                        
//                    }
//                    else {
                        // Update the corresponding message with the received response
                        //                    if let data = message.data(using: .utf8),
                        //                       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                        //                       let text = json["text"] as? Strin zx
                        
                        // if message type =
                        let text = message.text
                        strongSelf.messages[currentIndex].updateResponseText(text: text ?? "")
                        strongSelf.messages[currentIndex].toggleInteractingWithModel(isInteracting: false)
//                    }
                    
                    if let isEndOfStream = message.end_of_stream as? Bool, isEndOfStream {
                        
                        strongSelf.messages[currentIndex].toggleInteractingWithModel(isInteracting: false)
                        strongSelf.isEndOfStream = isEndOfStream
                        
                        
                        
                    }
                }
            }
        }
    }
    private func startResetTimer() {
        // Invalidate any existing timer
        resetTimer?.invalidate()
        
        // Start a new timer
        resetTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isInteractingWithModel = false
            }
        }
    }
}



extension ViewModel {
    var messagesAsString: String {
        return messages.map { "\($0.sendText) - \($0.responseText)" }.joined(separator: "\n")
    }
}

    
    struct WebSocketMessageOut: Codable {
        var text: String
        var user_secret: String
        var user_identifier: String
        var msg_id: String
        var app_version: String = Constants.app_version
        var is_suggested_input: Bool = false
        // other properties if needed...
    }


//    func speakLastResponse() {
//        #if !os(watchOS)
//        guard let synthesizer, let responseText = self.messages.last?.responseText, !responseText.isEmpty else {
//            return
//        }
//        stopSpeaking()
//        let utterance = AVSpeechUtterance(string: responseText)
//        utterance.voice = .init(language: "en-US")
//        utterance.rate = 0.5
//        utterance.pitchMultiplier = 0.8
//        utterance.postUtteranceDelay = 0.2
//        synthesizer.speak(utterance )
//        #endif
//    }
//
//    func stopSpeaking() {
//        #if !os(watchOS)
//        synthesizer?.stopSpeaking(at: .immediate)
//        #endif
//    }
//}

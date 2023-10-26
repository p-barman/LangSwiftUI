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
    
    @Published var isInteractingWithModel = false
    @Published var messages: [MessageRow] = []{
        didSet {
            print("Messages updated:", messages)
        }
    }
    @Published var inputMessage: String = ""
    @Published var webSocketVM = WebSocketViewModel(url: "ws://127.0.0.1:8000/ws/expl_user_identifier")
    //    @State messageRow: MessageRow()
    
    private let api: ChatUAPI
    
    init(api: ChatUAPI) {
        self.api = api
        self.webSocketVM.connect()
        
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
    
    
    @MainActor
    private func send(text: String) async {
        isInteractingWithModel = true
        
        // Construct the message object
        let webSocketMessage = WebSocketMessage(
            text: text,
            user_secret: "secret",
            user_identifier: "expl_user_identifier",
            msg_id: "1241"
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
        
        // Initialize the message row for the LangWallet response
        var langWalletMessageRow = MessageRow(
            isFromUser: false,
            isInteractingwithModel: true,
            sendImage: "langicon",
            sendText: "",
            responseImage: "langicon",
            responseText: ""
        )
        self.messages.append(langWalletMessageRow)
        
        // Capture the current message index for later use (LangWallet's index)
        let currentIndex = messages.count - 1
        
        // Define the response handling mechanism
        webSocketVM.onMessageReceived = { [weak self] message in
            DispatchQueue.main.async {
                self?.isInteractingWithModel = false
                if let strongSelf = self, currentIndex < strongSelf.messages.count {
                    // Update the corresponding message with the received response
                    if let data = message.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let text = json["text"] as? String {
                        
                        strongSelf.messages[currentIndex].updateResponseText(text: text)
                        strongSelf.messages[currentIndex].toggleInteractingWithModel(isInteracting: false)
                        
                        if let isEndOfStream = json["end_of_stream"] as? Bool, isEndOfStream {
                            strongSelf.messages[currentIndex].toggleInteractingWithModel(isInteracting: false)
                        }
                    }
                }
            }
        }
    }
}

    
    struct WebSocketMessage: Codable {
        var text: String
        var user_secret: String
        var user_identifier: String
        var msg_id: String
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

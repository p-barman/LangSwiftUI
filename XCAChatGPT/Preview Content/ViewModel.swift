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
    
    @Published var isInteractingwithModel = false
    @Published var messages: [MessageRow] = []
    @Published var inputMessage: String = ""
    @Published var webSocketVM = WebSocketViewModel(url: "wss://b752-136-62-199-186.ngrok-free.app")
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
        isInteractingwithModel = true
        var streamText = ""
        var messageRow = MessageRow(
            isInteractingwithModel: true,
            sendImage: "profile",
            sendText: text,
            responseImage: "openai",
            responseText: streamText,
            responseError: nil
        )
        
        self.messages.append(messageRow)
        
        do {
            //            let stream = try await api.sendMessageStream(text: text)
              webSocketVM.onMessageReceived = { [weak self] message in
                    messageRow.responseText = message
                    self?.messages[self?.messages.count ?? 0 - 1] = messageRow
                }
                
                // Send the message
                webSocketVM.send(message: text)
                
            //            for try await text in stream {
            //                streamText += text
            //                messageRow.responseText = streamText.trimmingCharacters(in: .whitespacesAndNewlines)
            //                self.messages[self.messages.count - 1] = messageRow
            //
            //                // Sending the responseText to the WebSocket after processing with your API:
            //                webSocketVM.send(message: messageRow.responseText)
            //            }
        }
//        } catch {
//            messageRow.responseError = error.localizedDescription
//        }
        
        // after sending a message, turn off interaction
        messageRow.isInteractingwithModel = false
        self.messages[self.messages.count - 1] = messageRow
        isInteractingwithModel = false
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
}

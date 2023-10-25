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
    @Published var webSocketVM = WebSocketViewModel(url: "wss://91be-136-62-199-186.ngrok-free.app")
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
        
        // Initialize the message row for the outgoing message
        var messageRow = MessageRow(
            isInteractingwithModel: true,
            sendImage: "profile",
            sendText: text,
            responseImage: "openai",
            responseText: "",
            responseError: nil
        )
        
        // Append the initialized message to the messages array
        self.messages.append(messageRow)
        
        // Capture the current message index for later use
        let currentIndex = messages.count - 1
        
        // Define the response handling mechanism
        webSocketVM.onMessageReceived = { [weak self] message in
            if let strongSelf = self, currentIndex < strongSelf.messages.count {
                // Update the corresponding message with the received response
                strongSelf.messages[currentIndex].responseText = message
                
                // Turn off the interaction after receiving the message
                strongSelf.messages[currentIndex].isInteractingwithModel = false
            }
        }
        
        // Send the outgoing message to the WebSocket server
        webSocketVM.send(message: text)
        
        // Once the message has been sent, update the message row to reflect the interaction state
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

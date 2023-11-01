//
//  WebSocketViewModel.swift
//  XCAChatGPT
//
//  Created by P on 2023-10-14.
//

import Foundation
import Combine
import UIKit

class WebSocketViewModel: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    private let urlString: String
    var onMessageReceived: ((WebsocketMessageData) -> Void)?
    
    private var unsentMessage: String?

    private var reconnectionDelay: TimeInterval = 1.0 // Starts with a 1 second delay
    private let maxReconnectionDelay: TimeInterval = 64.0 // Maximum delay is 64 seconds
    private let maxReconnectionAttempts = 5 // Adjust this value as necessary
    private var currentReconnectionAttempts = 0

//    @Published var messageReceived = ""
    
    init(url: String) {
        self.urlString = url
        self.urlSession = URLSession(configuration: .default)
        
        // Start connection immediately upon initialization
        self.connect()
        print("connected?")
        
        // Register for app lifecycle notifications
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appBecameActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    // Called when app goes to background
    @objc private func appMovedToBackground() {
        // Depending on your needs, you can either disconnect here or keep the connection alive
        // No need to do anything for keeping connection alive - but not gauaranteed by iOS
        // disconnect() // Uncomment if you wish to disconnect
    }
    
    // Called when app returns to foreground
    @objc private func appBecameActive() {
        // Reconnect if the connection was closed when the app went to the background
        if webSocketTask?.state != .running {
            connect()
        }
    }
    
    func connect() {
        // Check if the webSocketTask is already running
        if webSocketTask?.state == .running {
            print("WebSocket is already active.")
            return
        }

        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        

        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        if let message = unsentMessage {
            send(message: message)
            unsentMessage = nil  // Clear the stored message after resending
        }

        receiveMessage()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
    }

    private func attemptReconnection() {
        if currentReconnectionAttempts < maxReconnectionAttempts {
            DispatchQueue.global().asyncAfter(deadline: .now() + reconnectionDelay) { [weak self] in
                self?.connect()
            }

            reconnectionDelay = min(reconnectionDelay * 2, maxReconnectionDelay)
            currentReconnectionAttempts += 1
        } else {
            print("Max reconnection attempts reached. Please check your network and try again.")
        }
    }
    
    func send(message: String) {
        webSocketTask?.send(.string(message)) { [weak self] error in
                if let error = error {
                    print("Error sending message: \(error)")
                    
                    if (error as NSError).domain == "NSPOSIXErrorDomain" && (error as NSError).code == 57 {
                        print("Socket not connected. Attempting to reconnect...")
                        
                        // Store the message for retry only in case of an error
                        self?.unsentMessage = message

                        self?.attemptReconnection()
                    }
                }
            }

    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if let doubleEncodedData = text.data(using: .utf8),
                       let singleEncodedJsonString = String(data: doubleEncodedData, encoding: .utf8),
                       let jsonData = singleEncodedJsonString.data(using: .utf8) {
                        
                        do {
                            let messageData = try JSONDecoder().decode(WebsocketMessageData.self, from: jsonData)
                            DispatchQueue.main.async {
                                self?.handleMessageData(messageData)
                            }
                        } catch {
                            print("Decoding error: \(error)")
                        }
                        
                    } else {
                        print("Error converting text to data")
                    }
                default:
                    print("Received unhandled message type")
                }

                // Continue listening for the next message
                self?.receiveMessage()

            case .failure(let error):
                print("Error receiving message: \(error)")
                // Handle the error and decide if we need to reconnect
                self?.handleError(error)
            }
        }
    }







    private func handleError(_ error: Error) {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost:
                attemptReconnection()
            default:
                print("Received an error that doesn't warrant reconnection: \(urlError.localizedDescription)")
            }
        } else if error.localizedDescription.contains("Socket is not connected") || error.localizedDescription.contains("Could not connect to the server.") {
            // Handle socket not connected error
            attemptReconnection()
        } else {
            print("Received a non-URL error: \(error.localizedDescription) \(error)")
        }
    }
    private func handleMessageData(_ messageData: WebsocketMessageData) {
        var messageType = messageData.message_type

        if messageType == nil {
            print("Message type is nil. Defaulting to text.")
            messageType = .text
        }

        switch messageType {
            case .text:
                // Handle text
                self.onMessageReceived?(messageData) // this calls webSocketVM.onMessageReceived

            case .image:
                if let imageUrl = messageData.url {
                              // Create a new MessageRow with the image URL and add to your messages array.
                              let newMessage = MessageRow(isFromUser: false, isInteractingwithModel: false, sendImage: "", sendText: "", responseImage: "", responseText: "", imageUrl: imageUrl)
                              // Append newMessage to your messages array or use onMessageReceived callback to handle it externally.
//                              self.onMessageReceived?(newMessage)
                          }
               //image with text:
                if let text = messageData.text {
                    if Bool(text) != false {
                        self.onMessageReceived?(messageData)
                    }
                   
                }
               
//                break
                // Handle image
                // Depending on the data type, you can load the image from a URL, bytes, or file
                // Then display it using SwiftUI's Image view or other methods

            case .audio:
                break
                // Handle audio
                // You might want to play it or show a custom audio player UI

            //... Add more cases for video, animation, etc.

        default:
            print("Unsupported message type: \(messageType!.rawValue)")
        }
    }

}


import Foundation

struct WebsocketMessageData: Codable {
    let text: String?                // For text
    let message_type: MessageType?   // text, audio, image, video, animation
    let data_type: DataType?         // url, bytes, file
    let front_end_filename: String?  // e.g., render local sound, image, video, animation via frontend (fast)
    let url: String?
    let bytes: Data?
    let end_of_stream: Bool?// Note: Data type in Swift corresponds to bytes

    enum MessageType: String, Codable {
        case text, audio, image, video, animation
    }

    enum DataType: String, Codable {
        case url, bytes, file
    }
}

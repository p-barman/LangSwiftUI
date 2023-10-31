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

        receiveMessage()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
    }
    
    func send(message: String) {
        webSocketTask?.send(.string(message)) { error in
            if let error = error {
                print("Error sending message: \(error)")
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    // Decode the received string into WebsocketMessageData
                    if let data = text.data(using: .utf8),
                       let messageData = try? JSONDecoder().decode(WebsocketMessageData.self, from: data) {
                        DispatchQueue.main.async {
                            self?.handleMessageData(messageData)
                        }
                    } else {
                        print("Error decoding message data")
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
        // Here, you can add more refined error checks.
        // For demonstration purposes, I'll just use a generic error check.

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut:
                // For these types of errors, attempt a reconnection after a delay
                DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                    self.connect()
                }
            default:
                // For other types of errors, decide if you need to reconnect or handle differently
                print("Received an error that doesn't warrant reconnection: \(urlError.localizedDescription)")
            }
        } else {
            print("Received a non-URL error: \(error.localizedDescription)")
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
                self.onMessageReceived?(messageData)

            case .image:
                break
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

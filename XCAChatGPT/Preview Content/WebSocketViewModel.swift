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
    var onMessageReceived: ((String) -> Void)?

    @Published var messageReceived = ""

    init(url: String) {
        self.urlString = url
        self.urlSession = URLSession(configuration: .default)

        // Start connection immediately upon initialization
        self.connect()

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

//    private func receiveMessage() {
//        webSocketTask?.receive { [weak self] result in
//            switch result {
//            case .success(let message):
//                switch message {
//                case .string(let text):
//                    DispatchQueue.main.async {
//                        self?.messageReceived = text
//                    }
//                default:
//                    print("Received unhandled message type")
//                }
//
//                // Continue listening for the next message
//                self?.receiveMessage()
//            case .failure(let error):
//                print("Error receiving message: \(error)")
//            }
//        }
//    }
    private func receiveMessage() {
            webSocketTask?.receive { [weak self] result in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        DispatchQueue.main.async {
                            self?.onMessageReceived?(text)
                        }
                    default:
                        print("Received unhandled message type")
                    }
                    
                    // Continue listening for the next message
                    self?.receiveMessage()
                case .failure(let error):
                    print("Error receiving message: \(error)")
                }
            }
        }
}

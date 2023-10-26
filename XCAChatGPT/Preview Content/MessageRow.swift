//
//  MessageRow.swift
//  XCAChatGPT
//
//  Created by P on 2023-10-13.
//

import Foundation

class MessageRow: ObservableObject, Identifiable {


    @Published var isInteractingwithModel: Bool
    
    func updateResponseText(text: String) {
        self.responseText += text
    }

    func toggleInteractingWithModel(isInteracting: Bool) {
        self.isInteractingwithModel = isInteracting
    }
    
    let id = UUID()

    let sendImage: String
    let sendText: String

    let responseImage: String
    @Published var responseText: String

    var responseError: String?
    
    @Published var isFromUser: Bool
    
    init(isFromUser: Bool, isInteractingwithModel: Bool, sendImage: String, sendText: String, responseImage: String, responseText: String, responseError: String? = nil) {
        self.isInteractingwithModel = isInteractingwithModel
        self.sendImage = sendImage
        self.sendText = sendText
        self.responseImage = responseImage
        self.responseText = responseText
        self.responseError = responseError
        self.isFromUser = isFromUser
    }
    // Add an initializer if necessary...
}

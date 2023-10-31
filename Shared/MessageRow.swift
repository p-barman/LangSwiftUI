//
//  MessageRow.swift
//  XCAChatGPT
//
//  Created by P on 2023-10-13.
//

import Foundation
import SwiftUI

class MessageRow: ObservableObject, Identifiable, Equatable {

    @Published var isInteractingwithModel: Bool
    let id = UUID()

    let sendImage: String
    let sendText: String
    var imageUrl: String?
    let responseImage: String
    @Published var responseText: String
    @Published var attributedResponseText: NSAttributedString? // for links and url clickablity
    var responseError: String?
    @Published var isFromUser: Bool

    func updateResponseText(text: String) {
            self.responseText += text
            
            // Detect URLs and update the attributed string
            let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = detector?.matches(in: self.responseText, options: [], range: NSRange(location: 0, length: self.responseText.utf16.count))
            
            let attributedText = NSMutableAttributedString(string: self.responseText)
            for match in matches ?? [] {
                guard let range = Range(match.range, in: self.responseText) else { continue }
                attributedText.addAttribute(.link, value: self.responseText[range], range: match.range)
            }
            self.attributedResponseText = attributedText
        }
    

    func toggleInteractingWithModel(isInteracting: Bool) {
        self.isInteractingwithModel = isInteracting
    }
    
 

    
    static func == (lhs: MessageRow, rhs: MessageRow) -> Bool {
            return lhs.id == rhs.id
        }
    
    init(isFromUser: Bool, isInteractingwithModel: Bool, sendImage: String, sendText: String, responseImage: String, responseText: String, imageUrl: String? = nil, responseError: String? = nil) {
        self.isInteractingwithModel = isInteractingwithModel
        self.sendImage = sendImage
        self.sendText = sendText
        self.responseImage = responseImage
        self.responseText = responseText
        self.imageUrl = imageUrl
        self.responseError = responseError
        self.isFromUser = isFromUser
        self.attributedResponseText = NSAttributedString(string: responseText)
    }

    // Add an initializer if necessary...
}

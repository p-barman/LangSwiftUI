//
//  MessageRow.swift
//  XCAChatGPT
//
//  Created by P on 2023-10-13.
//

import Foundation

struct MessageRow: Identifiable {
    
    let id = UUID()
    
    var isInteractingwithModel: Bool
    
    let sendImage: String
    let sendText: String
    
    let responseImage: String
    var responseText: String
    
    var responseError: String?
}

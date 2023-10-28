//
//  XCAChatGPTApp.swift
//  XCAChatGPT
//
//  Created by Alfian Losari on 01/02/23.
//

import Foundation
import SwiftUI

import SwiftUI

//@main
//struct ChatApp: App {
//
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//
//    var body: some Scene {
//        WindowGroup {
////            ContentView()
//            Paywall(isPaywallPresented: true)
//        }
//    }
//}

@main
struct ChatApp: App {
    
    @StateObject var userStateModel = UserStateModel()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var isPaywallPresented: Bool = true

    var body: some Scene {
        WindowGroup {
            if isPaywallPresented {
                Paywall(isPaywallPresented: $isPaywallPresented)
            } else {
                // ContentView or whatever you want to show when the paywall is dismissed
                ContentView()
            }
        }
    }
}

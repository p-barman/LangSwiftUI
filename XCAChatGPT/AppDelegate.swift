//
//  AppDelegate.swift
//  XCAChatGPT
//
//  Created by P on 2023-10-25.
//

import Foundation


import UIKit
import Adapty

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        Adapty.activate("public_live_nJs3XlAe.ABYgz9pWslrvnZwnfdmI",  customerUserId: PersistentUserState.userIdentifier ?? "default", storeKit2Usage: .forIntroEligibilityCheck)
        
        return true
    }
}

//
//  AppDelegate.swift
//  XCAChatGPT
//
//  Created by P on 2023-10-25.
//

import Foundation
import UIKit
import UserNotifications
import Adapty

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Activate Adapty with the provided public key and user identifier
        Adapty.activate("public_live_nJs3XlAe.ABYgz9pWslrvnZwnfdmI", customerUserId: PersistentUserState.userIdentifier ?? "default", storeKit2Usage: .forIntroEligibilityCheck)
        
        // Check if backend is live and store the state
        UserStateModel.shared.checkIfBackendIsLive()
        
        Constants.fetchBackendVariables()
        // Set UNUserNotificationCenter delegate to self to handle incoming notifications
        UNUserNotificationCenter.current().delegate = self
        
        // Request authorization for notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if granted {
                print("Permission granted")
            } else if let error = error {
                print("Permission denied with error: \(error.localizedDescription)")
            } else {
                print("Permission denied")
            }
        }
        
        return true
    }

    
    // Handle incoming notification while app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Display the notification's title and content in the foreground
        completionHandler([.banner, .badge, .sound])
    }
    
    // Implement this function if you want to handle what happens when a notification is tapped by the user
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle the user's interaction with the notification
        completionHandler()
    }
    
    // Add additional functions if needed to handle user interactions with notifications
}

//
//  Notifications.swift
//  LangSwiftUI
//
//  Created by P on 2023-11-04.
//

import Foundation
import UIKit
import UserNotifications

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // It's best practice to call the checkForPermission() function here or at a point where you know the view is loaded and can safely trigger permission requests, etc.
        checkForPermission()
    }
    
    func checkForPermission() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                self.dispatchNotification() // The app is authorized to schedule or receive notifications.
            
            case .denied:
                // The user has explicitly denied permission for notifications.
                // You may want to inform the user or direct them to settings.
                print("Notifications were denied. Update settings if you want to receive them.")
                
            case .notDetermined:
                // The user has not yet made a choice regarding whether the app can schedule notifications.
                notificationCenter.requestAuthorization(options: [.alert, .sound]) { didAllow, error in
                    if didAllow {
                        self.dispatchNotification() // The user allowed notifications.
                    } else if let error = error {
                        // Handle the error here.
                        print("Error when requesting authorization: \(error.localizedDescription)")
                    }
                }
            
            case .provisional:
                // The application is authorized to post non-interruptive user notifications.
                self.dispatchNotification() // Dispatch a notification if appropriate.
            
            case .ephemeral:
                // The app is temporarily authorized to post notifications. This status is typically used for Focus modes.
                self.dispatchNotification() // Dispatch a notification if appropriate.
                
            @unknown default:
                // Handle any future cases that are unknown as of the current SDK.
                print("Unknown authorization status: \(settings.authorizationStatus)")
            }
        }
    }

    
    // Remove 'self' from function definition
    func dispatchNotification() {
        let identifier = "morning-notif" // Used to differentiate between different notifications
        let title = "It's time to make some moves!"
        let body = "Lets ride this liger, cowboy 🤠"
        let hour = 8
        let minute = 54
        let isDaily = true
        
        let notificationCenter = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default // Ensure this is the correct sound value
        
        let calendar = Calendar.current
        var dateComponents = DateComponents(calendar: calendar, timeZone: TimeZone.current)
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: isDaily)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Uncomment and correct this line to remove other pending notifications with the same identifier
        // notificationCenter.removeAllPendingNotificationRequests(withIdentifiers: [identifier])
        
        // Add notification to queue
        notificationCenter.add(request) { error in
            if let error = error {
                // Handle any errors
                print(error.localizedDescription)
            }
        }
    }
}




















//import UIKit
//
//class ViewController: UIViewController , UNUserNotificationCenterDelegate {
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // Do any additional setup after loading the view.
//        
//        
//        let center = UNUserNotificationCenter.current()
//        center.delegate = self
//        center.requestAuthorization(options: [.badge,.sound,.alert]) { granted, error in
//            if error == nil {
//                print("User permission is granted : \(granted)")
//            }
//      }
//    //        Step-2 Create the notification content
//            let content = UNMutableNotificationContent()
//            content.title = "Hello"
//            content.body = "Welcome"
//       
//        
//    //        Step-3 Create the notification trigger
//            let date = Date().addingTimeInterval(5)
//            let dateComponent = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second], from: date)
//            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: false)
//        
//        
//        
//    //       Step-4 Create a request
//            let uuid = UUID().uuidString
//            let request = UNNotificationRequest(identifier: uuid, content: content, trigger: trigger)
//            
//        
//    //      Step-5 Register with Notification Center
//            center.add(request) { error in
//        
//        
//            }
//    }
//
//    func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                willPresent notification: UNNotification,
//                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//         completionHandler([.sound,.alert])
//    }
//
//}

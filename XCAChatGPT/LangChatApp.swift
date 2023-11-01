//
//  XCAChatGPTApp.swift
//  XCAChatGPT
//
//  Created by Alfian Losari on 01/02/23.
//

import Foundation
import SwiftUI
import Adapty


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
    @StateObject var paywallManager = PaywallManager()

    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var isPaywallPresented: Bool = true
    @State var showTerms : Bool = !UserDefaults.standard.bool(forKey: "agreedToTerms")
    
    init() {
        var agreedtoTS = UserDefaults.standard.bool(forKey: "agreedToTerms")
        if agreedtoTS {self.showTerms = false}
        if !agreedtoTS {self.showTerms = true}
    }

    var body: some Scene {
        WindowGroup {
            if paywallManager.shouldShowPaywall && userStateModel.isSubscriptionActive {
                Paywall(isPaywallPresented: $isPaywallPresented)
            } else {
//                // ContentView or whatever you want to show when the paywall is dismissed
//                ContentView()
//            }
            ContentView(paywallManager: paywallManager)
                .sheet(isPresented: $showTerms ) {
                    GeometryReader { geometry in
                        AgreeToTermsView(isPresented: $showTerms)
                            .environment(\.horizontalSizeClass, .regular)
                            .environment(\.verticalSizeClass, .regular)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                            .interactiveDismissDisabled()
                        
                            .environmentObject(userStateModel)
                            .preferredColorScheme(.dark)
                            .onAppear {
                                if Adapty.delegate == nil {
                                    Adapty.delegate = appDelegate as? any AdaptyDelegate
                                }
                                DispatchQueue.main.async {
                                    //ensure existing users who used to be subscribed have their subscriptions paywalled
                                    Adapty.getProfile { result in
                                        if let profile = try? result.get(),
                                           profile.accessLevels["premium"]?.isActive ?? false {
                                            
                                            print("this user is subscribed to ", profile.subscriptions)
                                            userStateModel.isSubscriptionActive = true
                                            // grant access to premium features
                                        }
                                        else {
                                            print("this user not subscribed ")
                                            userStateModel.isSubscriptionActive = false
                                        }
                                        if let p =  try? result.get() { //get Adapty Profile id to pass into report/filter
                                            userStateModel.profileId = p.profileId
                                            
                                        }
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
}



struct UserProfile {
    static var shared = UserProfile()
    private init() {}
    var profileId: String = ""
}

//
//  XCAChatGPTApp.swift
//  XCAChatGPT
//
//  Created by Alfian Losari on 01/02/23.
//

import Foundation
import SwiftUI
import Adapty

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@main
struct ChatApp: App {
    
    @StateObject var userStateModel = UserStateModel()
    @StateObject var paywallManager = PaywallManager()

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isAppReady = false  // New state to control the display of LoadView
    @State private var isPaywallPresented: Bool = true
    @State var showTerms : Bool = !UserDefaults.standard.bool(forKey: "agreedToTerms")
    
    init() {
        var agreedtoTS = UserDefaults.standard.bool(forKey: "agreedToTerms")
        if agreedtoTS {self.showTerms = false}
        if !agreedtoTS {self.showTerms = true}
    }

    var body: some Scene {
        WindowGroup {
            if !isAppReady {
                           // Show the LoadView on app start
                           LoadView(isAppReady: $isAppReady)
                       } else if paywallManager.shouldShowPaywall && !userStateModel.isSubscriptionActive { // not active?!
                Paywall(isPaywallPresented: $isPaywallPresented)
                    .environmentObject(paywallManager)
                    .environmentObject(userStateModel)
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


import SwiftUI
import Lottie

struct LoadView: View {
    @State private var imageOpacity = 0.0
    @Binding var isAppReady: Bool

    var body: some View {
        ZStack {

            // Image that fades in
            Image("langicon") // Replace "langicon" with your actual image name in your assets
                .resizable()
//                .aspectRatio(contentMode: .fit)
//                .scaleEffect(0.5) // Adjust the scale to fit your design
                .opacity(imageOpacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 3)) {
                        self.imageOpacity = 1.0
                    }
                }

            // Lottie animation view
            LottieView(name: "alien", loopMode: .loop)
//                .opacity(imageOpacity) // Bind the opacity of the Lottie view to the image's opacity
                .onAppear {
                    // Start the Lottie animation with a delay after the image has faded in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            self.imageOpacity = 0 // You might want to fade out the Lottie animation or just remove it after it's done
                            isAppReady = true
                        }
                    }
                }
        }
    }
}


import Foundation
import SwiftUI

struct PersistentUserState {
    
    private static let userDefaults = UserDefaults.standard
    
    // Key for the stored identifier
    private static let UserIdentifierKey = "expl_user_identifier_key"
    private static let UserNameKey = "expl_user_name_key" // This is the new key for storing the user's name
    
    // Getter and Setter for the identifier
    static var userIdentifier: String? {
        get {
            if let identifier = userDefaults.string(forKey: UserIdentifierKey) {
                return identifier
            } else {
                // If not set previously, set it now.
                let newIdentifier = UUID().uuidString
                userDefaults.setValue(newIdentifier, forKey: UserIdentifierKey)
                return newIdentifier
            }
        }
        set {
            userDefaults.setValue(newValue, forKey: UserIdentifierKey)
        }
    }
    // Getter and Setter for the user name
        static var userName: String? {
            get {
                return userDefaults.string(forKey: UserNameKey)
            }
            set {
                userDefaults.setValue(newValue, forKey: UserNameKey)
            }
        }
}



struct Constants {
    static let environment: Environment = .dev// change to .prod when needed
    static let app_version: String = "0.011"
    
    enum Environment {
        case dev
        case prod
    }

    // Base URLs
    static var baseWebSocketURL: String {
        switch environment {
        case .dev:
            return "ws://127.0.0.1:8000/ws"
        case .prod:
            return "ws://34.123.113.101:8000/ws"
        }
    }
    
    static var baseHttpURL: String {
        switch environment {
        case .dev:
            return "http://127.0.0.1:8000"
        case .prod:
            return "http://34.123.113.101:8000"
        }
    }
    
    // Paths
    // Corrected Paths
    static var userIdentifierPath: String {
        return "/\(PersistentUserState.userIdentifier ?? "expl_user_identifier345")"
    }
    static let suggestedUserInputsPath = "/suggested_user_inputs"
    static let filterContentPath = "/filter_content"
    static let reportContentPath = "/report_content"
    
    // Corrected Full URLs

    // Full URLs
    static var webSocketURL: String {
           return "\(baseWebSocketURL)\(userIdentifierPath)"
       }
    
//    static var httpUrl: String {
//        return "\(baseHttpURL)\(explUserIdentifierPath)"
//    }
//
    static var httpUrlForSuggestedInputs: String {
        return "\(baseHttpURL)\(suggestedUserInputsPath)"
    }
    
    static var httpUrlForFilterContent: String {
        return "\(baseHttpURL)\(filterContentPath)"
    }
    
    static var httpUrlReportConent: String {
        return "\(baseHttpURL)\(reportContentPath)"
    }
    
    // ... other constants and paths
}



// MARK: AGREED TO TERMS OR SERVICE

struct AgreeToTermsView: View {
    @StateObject var userStateModel = UserStateModel()
    @Binding var isPresented: Bool
    

    var body: some View {
        VStack {
            Text("Please agree to the terms of use (EULA):")
            Spacer().frame(maxHeight: 10)
            HStack {
               // Text("(Read the")
                Button(action: {
                    if let url = URL(string: "https://docs.google.com/document/u/1/d/e/2PACX-1vQnpEpthNFVto9C-7M741a4EtHWRjrAsOY98I728zCRg5Ix1CFP4VUr9HlCDJkmlziYg6fPB3jrdyed/pub") {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                    
                    // add code to open link in browser here
                }) {
                    Text("Terms of Service").underline()
                }
//                Text(")")
            }
            Spacer().frame(maxHeight: 60)
            Button(action: {
            
                isPresented = false
                userStateModel.agreedToTerms = true
                UserDefaults.standard.set(true, forKey: "agreedToTerms")

            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue)
                        .frame(width: 120, height: 40)
                   
                    Text("Agree")
                        .foregroundColor(.white)
                    
                }
            }
        }
        .padding()
        // .background(Color.black)
        .foregroundColor(Color.white)
        
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}


class PaywallManager: ObservableObject {

    @Published var shouldShowPaywall: Bool = false
    @Published var max: Int // todo make dependent on dev v prod?
    private static let MessagesSentKey = PersistentUserState.userIdentifier!
    private let userDefaults = UserDefaults.standard
    
    var messagesSent: Int {
        get {
            return userDefaults.integer(forKey: PaywallManager.MessagesSentKey)
        }
        set { //do in background
            DispatchQueue.global(qos: .background).async {
                self.userDefaults.setValue(newValue, forKey: PaywallManager.MessagesSentKey)
                self.userDefaults.synchronize()
                DispatchQueue.main.async {
                    self.checkForPaywall()
                }
            }
        }
    }

    init() {
         // Check on init so that it has the right value from the beginning
        switch Constants.environment {
        case .dev:
            max = 300
        case .prod:
            max = 4
        }
        checkForPaywall()
    }
    
    func incrementMax() {
            print("increamenting max messages from ", max, "to ", (max + 10))
            max += 10
            checkForPaywall()
        }

    private func checkForPaywall() {
        if messagesSent > max {
            print("showing paywall ", "messages sent: ", messagesSent, "current max: ", max)
            shouldShowPaywall = true
        }
    }
}

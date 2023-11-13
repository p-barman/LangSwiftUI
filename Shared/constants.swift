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



//import Foundation


struct Constants {
    
    static let environment: Environment = .prod// Change to .prod when needed
    //Backend vars
    static var app_version: String = "0.011"
    static var is_backend_live: Bool = false
    static var max_num_messages: Int = 8
    static var max_num_messages_dev: Int = 300
    
    enum Environment {
        case dev
        case prod
    }
    
    static let maxMessages = 80
    static let maxMessagesResetHours = 8

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
    static var userIdentifierPath: String {
        return "/\(PersistentUserState.userIdentifier ?? "expl_user_identifier345")"
    }
    static let suggestedUserInputsPath = "/suggested_user_inputs"
    static let filterContentPath = "/filter_content"
    static let reportContentPath = "/report_content"
    static let userStatePath = "/get_user_state"
    static let isBackendLivePath = "/backend_is_live"
    static let backendVariablesPath = "/get_backend_variables"
    
    // Full URLs
    static var webSocketURL: String {
        return "\(baseWebSocketURL)\(userIdentifierPath)"
    }
    
    static var httpUrlForSuggestedInputs: String {
        return "\(baseHttpURL)\(suggestedUserInputsPath)"
    }
    
    static var httpUrlForFilterContent: String {
        return "\(baseHttpURL)\(filterContentPath)"
    }
    
    static var httpUrlReportContent: String {
        return "\(baseHttpURL)\(reportContentPath)"
    }
    
    static var httpUrlForUserState: String {
        return "\(baseHttpURL)\(userStatePath)"
    }
    
    static var httpUrlForBackendLive: String {
        return "\(baseHttpURL)\(isBackendLivePath)"
    }
    static var httpUrlForBackendVariables: String {
        return "\(baseHttpURL)\(backendVariablesPath)"
    }

    // Function to fetch and update backend variables
    // Function to fetch and update backend variables
    // Function to fetch and update backend variables
    static func fetchBackendVariables() {
        guard let url = URL(string: Constants.httpUrlForBackendVariables) else {
            print("Invalid URL for backend variables.")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            // Check for any errors
            if let error = error {
                print("Error fetching backend variables: \(error.localizedDescription)")
                return
            }

            // Make sure we got data
            guard let data = data else {
                print("Did not receive data")
                return
            }

            // Parse the JSON
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Extract each variable from the JSON object
//                    if let isBackendLive = jsonObject["is_backend_live"] as? Bool {
//                        Constants.is_backend_live = isBackendLive
//                    } else {
//                        print("Could not parse 'is_backend_live' from JSON")
//                    }

                    if let maxNumMessages = jsonObject["max_num_messages"] as? Int {
                        Constants.max_num_messages = maxNumMessages
                        print(Constants.max_num_messages)

                    } else {
                        print("Could not parse 'max_num_messages' from JSON")
                    }

                    if let appVersion = jsonObject["app_version"] as? String {
                        Constants.app_version = appVersion
                        print("Constants.app_version ", Constants.app_version)
                    } else {
                        print("Could not parse 'app_version' from JSON")
                    }
                } else {
                    print("Could not parse JSON into a dictionary")
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }
        // Start the task
        task.resume()
    }

}


// The rest of your Swift code would remain the same.




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
            max = Constants.max_num_messages // change to max_num_messages_dev
        case .prod:
            max = Constants.max_num_messages
        }
        checkForPaywall()
    }
    
    func incrementMax() {
            print("increamenting max messages from ", max, "to ", (max + 10))
            Constants.max_num_messages += 10
            Constants.max_num_messages_dev += 10
            checkForPaywall()
        }

    private func checkForPaywall() {
        print(messagesSent)
        print(Constants.max_num_messages)
        if messagesSent > Constants.max_num_messages {
            print("showing paywall ", "messages sent: ", messagesSent, "current max: ", max)
            shouldShowPaywall = true
        }
    }
}

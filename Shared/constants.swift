import Foundation

struct PersistentUserState {
    
    private static let userDefaults = UserDefaults.standard
    
    // Key for the stored identifier
    private static let UserIdentifierKey = "expl_user_identifier_key"
    
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
}


struct Constants {
    static let environment: Environment = .dev // change to .prod when needed
    
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
            return "ws://http://34.123.113.101:8000/ws"
        }
    }
    
    static var baseHttpURL: String {
        switch environment {
        case .dev:
            return "http://127.0.0.1:8000"
        case .prod:
            return "http://http://34.123.113.101:8000"
        }
    }
    
    // Paths
    // Corrected Paths
    static var userIdentifierPath: String {
        return "/\(PersistentUserState.userIdentifier ?? "expl_user_identifier")"
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

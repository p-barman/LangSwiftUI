//
//  File.swift
//  LangSwiftUI
//
//  Created by P on 2023-11-06.
//

import Foundation
import Adapty


class UserStateModel: ObservableObject {
    
    @Published var isSubscriptionActive = false
    @Published var userState: UserStateResponse?
   
    @Published var agreedToTerms: Bool = (UserDefaults.standard.bool(forKey: "agreedToTerms") ?? false)
    @Published var isBackendLive: Bool = false
    @Published var profileId: String = ""  // to reference in app wheter user has active subscription
    static let shared = UserStateModel()
    init() {
        self.agreedToTerms = UserDefaults.standard.bool(forKey: "agreedToTerms")
        
        
        // TO DO: CHECK IF BACKEND IS LIVE. IF LIVE = RENDER SOME PROPERTIES ON UI
        Adapty.getProfile { result in
            if let profile = try? result.get() as? AdaptyProfile,
               profile.accessLevels["premium"]?.isActive ?? false {
                
                print("this user is subscribed to: ", profile.subscriptions)
                self.isSubscriptionActive = true
                
            }
        }

    }
    
    // Function to fetch user state
    func fetchUserState(userIdentifier: String) {
        guard let url = URL(string: Constants.httpUrlForUserState) else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let token = "this-is-actually-loop"  // Replace with your actual token
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: String] = ["user_identifier": userIdentifier]
        request.httpBody = try? JSONEncoder().encode(body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Error fetching user state: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received from fetchUserState")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                // Customize the date decoding if necessary
                decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
                
                let userStateResponse = try decoder.decode(UserStateResponse.self, from: data)
                DispatchQueue.main.async {
                    // Here you update your properties based on the userStateResponse
                    self?.userState = userStateResponse
                    self?.profileId = userStateResponse.httpUsername ?? ""
                    // Set other properties as needed
                }
            } catch {
                print("Error decoding user state: \(error)")
            }
        }.resume()
    }
    
    func checkIfBackendIsLive() {
        guard let url = URL(string: Constants.httpUrlForBackendLive) else {
            DispatchQueue.main.async {
                print("Backend Live Check: URL is not valid.")
                self.isBackendLive = false
            }
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                  error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    print("Backend Live Check: Failed to receive a valid response or status code not 200.")
                    self?.isBackendLive = false
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Bool],
                   let isBackendLive = json["backend_is_live"] {
                    DispatchQueue.main.async {
                        self?.isBackendLive = isBackendLive
                        print("Backend Live Check: Backend is live (\(isBackendLive)).")
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.isBackendLive = false
                        print("Backend Live Check: Failed to parse JSON response.")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.isBackendLive = false
                    print("Backend Live Check: JSON parsing error: \(error).")
                }
            }
        }
        
        task.resume()
    }


}

extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}


struct UserOwnedAddress: Codable {
    let UUID: Int
    let userAddress: String

    enum CodingKeys: String, CodingKey {
        case UUID
        case userAddress = "user_address"
    }
}

struct UserStateResponse: Codable {
    let UUID: Int
    let createdAt: Date
    let phoneNumberOrEmail: String?
    let httpUsername: String?
    let twitterHandle: String?
    let userAddress: String
    let currentChain: String?
    let addressBook: String?
    let fiatOrCryptoFundingTx: String
    let userHasFundedAccount: Bool?
    let userOwnedAddress: [UserOwnedAddress]?
    let subscriptionStatus: String?
    let stripeCustomerId: String?
    let streamId: String

    enum CodingKeys: String, CodingKey {
        case UUID
        case createdAt = "created_at"
        case phoneNumberOrEmail = "phone_number_or_email"
        case httpUsername = "http_username"
        case twitterHandle = "twitter_handle"
        case userAddress = "user_address"
        case currentChain = "current_chain"
        case addressBook = "address_book"
        case fiatOrCryptoFundingTx = "fiat_or_crypto_funding_tx"
        case userHasFundedAccount = "user_has_funded_account"
        case userOwnedAddress = "user_owned_address"
        case subscriptionStatus = "subscription_status"
        case stripeCustomerId = "stripe_customer_id"
        case streamId = "stream_id"
    }
}

// Date decoding strategy if needed
//let decoder = JSONDecoder()
//decoder.dateDecodingStrategy = .iso8601  // Adjust the date format if necessary

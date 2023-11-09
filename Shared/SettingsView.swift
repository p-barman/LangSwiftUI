//
//  SettingsView2.swift
//  XCAChatGPT
//
//  Created by P on 2023-10-25.
//

import Foundation
import SwiftUI




struct SettingsView: View {
    
    @Binding var showSettings: Bool
    @ObservedObject var viewModel: ViewModel
    @State private var user_report_text: String = ""
    @Environment(\.requestReview) var requestReview
    @FocusState var isFocused: Bool
    @State private var showAlert: Bool = false
//    @State private var userName: String = "your profile"
    @State private var userName: String = PersistentUserState.userName ?? ""
    @State private var animateHeart: Bool = false
//    @StateObject var userStateModel = UserStateModel()
    @EnvironmentObject var userStateModel: UserStateModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                List {
                    userProfile
                    //
                                      if !userStateModel.isBackendLive {
                                          currentBlockchainDetails
                                      }
                    switchPlatforms
                    flagComment
                    
                }
                .navigationTitle("Settings")
                .navigationBarItems(leading: Button(action: {
                    showSettings.toggle()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                    Text("Back")
                        .foregroundColor(.blue)
                })
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Report Sent"), message: Text("Thank you for your feedback. We will review the report."), dismissButton: .default(Text("OK")))
                }
//                Divider()
//                Spacer(minLength: 10)
                // Heart emoji button positioned outside the List
                if animateHeart {
                    Button(action: {
                        requestReview()
                    }) {
                        Text("❤️")
                            .font(.title)  // Adjusting to a smaller size
                            .scaleEffect(0.5)  // Applying a scale effect
                            .opacity(0.8)  // Change the opacity for a pulsating effect
                            .animation(Animation.easeInOut(duration: 0.5), value: animateHeart)  // Pulsating animation
                    }
                    .padding(.bottom, 5) // position it closer to the bottom
                        .padding(.trailing, 9) // Adjust padding to push it closer to the right edge
                        .position(x: geometry.size.width - 50, y: geometry.size.height - 50)
                }            }
            .highPriorityGesture(
                        DragGesture(minimumDistance: 25)
                            .onEnded { value in
                                let horizontalDistance = value.location.x - value.startLocation.x
                                let verticalDistance = value.location.y - value.startLocation.y
                                if horizontalDistance < 0 {
                                    // Detected swipe from right to left
                                    showSettings.toggle()
                                } else if verticalDistance > 0 {
                                    // Detected swipe from top to bottom
                                    showSettings.toggle()
                                }
                            }
                    )
            .onAppear() {
                animateHeart = true
                userStateModel.fetchUserState(userIdentifier: PersistentUserState.userIdentifier ?? "0x2845674dfuygh7g45F87") // MARK: GET USER INFO BY STREAM ID
            }
        }
    }
    


    var flagComment: some View {
        Section(header: Text("Report Content")) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $user_report_text)
                    .frame(height: 70)
                    .focused($isFocused)
                if user_report_text.isEmpty {
                    Text("Reason for flagging content")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
            }
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            isFocused = false
                        }
                    }
                }
            }
            
            HStack {
                Button("Clear") {
                    withAnimation {
                        user_report_text = ""
                        isFocused = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(user_report_text.isEmpty)
                
                Button ("Report Content") {
                    withAnimation {
                        let messagesString = viewModel.messages.map { $0.sendText + " - " + $0.responseText }.joined(separator: "\n")
                                            
                                            // Pass the messagesString to your sendReport function
                        sendReport(user_report_text: user_report_text, convo: messagesString)
                                            
                        user_report_text = ""
                        isFocused = false
                    }
                }
            }
        }
    }
    
    
// MARK: USER PROFILE TAB
    @Environment(\.openURL) var openURL
    @ObservedObject var clipboardManager = ClipboardManager()

    var userProfile: some View {
        VStack {
            HStack {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
                    
                VStack(alignment: .leading) {
                    TextField("Enter your name", text: $userName, onCommit: {
                        commitUserName()
                    })
                    .font(.title2)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.bottom, 8)

                    VStack(alignment: .leading, spacing: 4) {
                        if let userAddress = userStateModel.userState?.userAddress {
                            HStack {
                                Text("Your address:").font(.system(size: 15))
                                Spacer()
                                Button(action: {
                                    clipboardManager.copyToClipboard(text: userAddress)
                                }) {
                                    Image(systemName: "clipboard")
                                        .imageScale(.small)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            Button(action: {
                                if let url = URL(string: "https://etherscan.io/address/\(userAddress)") {
                                    openURL(url)
                                }
                            }) {
                                Text(userAddress)
                                    .underline()
                                    .foregroundColor(.blue)
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                        } else {
                            Text("Address not available").font(.system(size: 12))
                        }
                    }
                    .padding(.leading)

                    // Optional: Confirmation view for clipboard copy
                    if clipboardManager.showingCopyConfirmation {
                        ConfirmationView()
                            .transition(.scale)
                    }
                }
                .padding(.leading)
            }
            .padding()
            Spacer()  // Add a spacer to fill the remaining space
        }
        .gesture(
            TapGesture()
                .onEnded { _ in
                    commitUserName()
                }
        )
    }




    func commitUserName() {
        PersistentUserState.userName = userName
        hideKeyboard()
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

 // MARK: TO DO - FUND WALLET BUTTON


 // MARK: PLATFORMS (IMESSAGE AND SMS)
    
    var switchPlatforms: some View {
        Section(header: Text("Switch Platforms")) {
            HStack {
                panelDetails(iconColor: .blue, iconName: "message.fill")
                Text("iMessage")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .onTapGesture {
                let message = "Hey u!"
                let sms: String = "sms:cryptoai@imsg.chat&body=\(message)"
                let strURL: String = sms.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                if let url = URL(string: strURL) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }

            HStack {
                panelDetails(iconColor: .green, iconName: "message.fill")
                Text("SMS")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .onTapGesture {
                let message = "Hey u!"
                let sms: String = "sms:+15128976483&body=\(message)"
                let strURL: String = sms.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                if let url = URL(string: strURL) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }

        }
    }
    
    // MARK: CHAIN ID, NETWORK AND WALLET FUNDED STATUS?
    
    var currentBlockchainDetails: some View {
        Section(header: Text("Details")) {
            HStack {
                panelDetails(iconColor: .blue, iconName: "link")
                Text("Chain ID")
                Spacer()
                Text(userStateModel.userState?.currentChain ?? "42161")
                                .font(.system(size: 17))
                                .foregroundColor(.gray)
            }

            HStack {
                panelDetails(iconColor: .green, iconName: "cube")
                Text("Network name")
                Spacer()
                Text(userStateModel.currentNetworkName)
                                .font(.system(size: 17))
                                .foregroundColor(.gray)

            }
            
            HStack {
                panelDetails(iconColor: .yellow, iconName: "dollarsign.square.fill")
                Text("Funds available")
                Spacer()
                Image(systemName: userStateModel.userState?.userHasFundedAccount ?? false ? "checkmark.circle" : "multiply.circle")
                                            .foregroundColor(userStateModel.userState?.userHasFundedAccount ?? false ? .green : .red)

            }

        }
    }
    
    
    
    struct SimpleData: Codable {
        let text: String
    }
    func sendReport(user_report_text: String, convo: String) {
        let url = URL(string: Constants.httpUrlReportConent)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let data = SimpleData(text: " User report: " + user_report_text + " \n Convo: " + convo)
        let jsonData = try? JSONEncoder().encode(data)

        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { _, response, error in
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                print("Failed to report content. Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            print("Successfully reported content.")
        }.resume()
    showAlert = true
    }

    
}

struct SettingsViewButton: View {
    @Binding var showSettings: Bool

    var body: some View {
        Button(action: { showSettings.toggle() }) {
            Image(systemName: "ellipsis.circle.fill")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(Color.gray.opacity(0.5))
        }
    }
}


struct panelDetails: View {
    
    let iconColor: Color
    let iconName: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(iconColor)
                .frame(width: 20, height: 20)
            Image(systemName: iconName).foregroundColor(.white).imageScale(.small)
        }
    }
    
}

enum NetworkName: String {
    case ethereum = "1"
    case arbitrum = "42161"
    case polygon = "137"

    var displayName: String {
        switch self {
        case .ethereum:
            return "Ethereum Mainnet"
        case .arbitrum:
            return "Arbitrum"
        case .polygon:
            return "Polygon Mainnet"
        }
    }
}

extension UserStateModel {
    var currentNetworkName: String {
        guard let currentChainString = userState?.currentChain,
              let network = NetworkName(rawValue: currentChainString) else {
            return "Arbitrum Mainnet" // Or any default you prefer
        }
        return network.displayName
    }
}







//struct SettingsView_Preview: PreviewProvider {
//    @State static private var showSettingsView = true
//    
//    static var previews: some View {
//        NavigationStack {
//            SettingsView(showSettings: $showSettingsView, )
//        }
//    }
//}

//
//struct leaveReview {
//    
//}



// Show current chain from UserState
//                    if let currentChain = userStateModel.userState?.currentChain {
//                        Text("Chain ID: \(currentChain)").font(.system(size: 12))
//                    } else {
//                        Text("Chain ID: 42161").font(.system(size: 12))
//                    }

                   // Show icon based on userHasFundedAccount status
//                    HStack {
//                        Image(systemName: userStateModel.userState?.userHasFundedAccount ?? false ? "circle.fill" : "xmark.circle.fill")
//                            .foregroundColor(userStateModel.userState?.userHasFundedAccount ?? false ? .green : .red)
//                        Text("Funds available")
//                    }

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
    @FocusState var isFocused: Bool
    @State private var showAlert: Bool = false
    @State private var userName: String = "your profile"

    var body: some View {
            List {
                userProfile
                switchPlatforms
                flagComment
            }
            .navigationTitle("Settings")
            .navigationBarItems(leading: Button(action: { // Add this
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
        }
    
    var flagComment: some View {
        Section(header: Text("Report Content")) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $user_report_text)
                    .frame(height: 100)
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
    
    var userProfile: some View {
        // Move @State declaration to the top level of SettingsView
        
        HStack {
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)
                
            VStack(alignment: .leading) {
                Text(self.userName)
                    .font(.title2)
                    .foregroundColor(.black)
                    .background(RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray, lineWidth: 1)
                        .background(Color.white))
                
                Text(PersistentUserState.userIdentifier ?? "0x2845674dfuygh7g45F87").font(.system(size: 12))
            }
            .padding(.leading)
        }
        .padding()
    }


        
    
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



//struct SettingsView_Preview: PreviewProvider {
//    @State static private var showSettingsView = true
//    
//    static var previews: some View {
//        NavigationStack {
//            SettingsView(showSettings: $showSettingsView, )
//        }
//    }
//}

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
    
    
    var body: some View {
            List {
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
        Section {
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






//struct SettingsView_Preview: PreviewProvider {
//    @State static private var showSettingsView = true
//    
//    static var previews: some View {
//        NavigationStack {
//            SettingsView(showSettings: $showSettingsView, )
//        }
//    }
//}

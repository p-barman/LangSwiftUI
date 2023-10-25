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
    
    @State private var flagText: String = ""
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
                TextEditor(text: $flagText)
                    .frame(height: 100)
                    .focused($isFocused)
                if flagText.isEmpty {
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
                        flagText = ""
                        isFocused = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(flagText.isEmpty)
                
                Button ("Report Content") {
                    withAnimation {
                        sendReport(content: flagText)
                        flagText = ""
                        isFocused = false
                    }
                }
            }
        }
    }
    
    func sendReport(content: String) {
        // Here, you'd typically send this content to your backend server.
        // For now, I'll just show an alert for demonstration purposes.
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






struct SettingsView_Preview: PreviewProvider {
    @State static private var showSettingsView = true
    
    static var previews: some View {
        NavigationStack {
            SettingsView(showSettings: $showSettingsView)
        }
    }
}

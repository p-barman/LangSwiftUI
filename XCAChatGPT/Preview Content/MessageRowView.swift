//
//  MessageRowView.swift
//  XCAChatGPT
//
//  Created by P on 2023-10-13.
//

import SwiftUI



struct MessageRowView: View {
    
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    
    let message: MessageRow
    let retryCallback: (MessageRow) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            messageRow(text: message.sendText, image: message.sendImage, bgColor: colorScheme == .light ? .white : Color(red:52/255, green: 53/255, blue: 65/255, opacity: 0.5))
            
            if let text = message.responseText {
                Divider()
                messageRow(text: text, image: message.responseImage, bgColor: colorScheme == .light ? .gray.opacity(0.5) : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 1), responseError: message.responseError, showDotLoading: message.isInteractingwithModel)
                Divider()
            }
        } // V Stack closed
    }
    
    func messageRow(text: String, image: String, bgColor: Color, responseError: String? = nil, showDotLoading: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 24) {
            if image.hasPrefix("http"), let url = URL(string: image) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .frame(width: 25, height: 25)
                        .cornerRadius(5)
                } placeholder: {
                    ProgressView()
                }
            } else {
                Image(image)
                    .resizable()
                    .frame(width: 25, height: 25)
                    .cornerRadius(5)
            }
            VStack(alignment: .leading) {
                if !text.isEmpty {
                    Text(text)
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
//                        .background(bgColor)
                        
                    
                }
                
                if let error = responseError {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                    
                    Button("Regenerate response") {
                        retryCallback(message)
                    }
                    .foregroundColor(.accentColor)
                    .padding(.top)
                }
                
                if showDotLoading {
                    DotLoadingView()
                        .frame(width: 60, height: 30)
                }
            }
            // H Stack closed
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bgColor)
        }
    }
    
    // Moved the preview outside of the main struct.
    struct MessageRowView_Previews: PreviewProvider {
        static let message = MessageRow(isInteractingwithModel: false, sendImage: "profile", sendText: "How old am i?", responseImage: "openai", responseText: "30!!!!")
        
        static let message2 = MessageRow(isInteractingwithModel: true, sendImage: "profile", sendText: "How old am i?", responseImage: "openai", responseText: "30!!!!")
        
        static var previews: some View {
            NavigationView {
                ScrollView {
                    MessageRowView(message: message, retryCallback: { _ in })
                        .frame(width: 400)
                        .previewLayout(.sizeThatFits)
                }
            }
        }
    }
}

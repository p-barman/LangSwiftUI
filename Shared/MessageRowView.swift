//
//  MessageRowView.swift
//  XCAChatGPT
//
//  Created by P on 2023-10-13.
//
import Foundation
import SwiftUI

struct MessageRowView: View {
    
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @ObservedObject var message: MessageRow
    let retryCallback: (MessageRow) -> Void

    var body: some View {
        VStack(spacing: 10) {
            if message.isFromUser {
                UserMessageRow(text: message.sendText, image: message.sendImage)
                    .frame(maxWidth: .infinity, alignment: .trailing) // User on the LEFT
            } else {
                LangMessageRow(text: message.responseText ?? "", image: message.responseImage, responseError: message.responseError, showDotLoading: message.isInteractingwithModel || message.responseText.isEmpty)
                    .frame(maxWidth: .infinity, alignment: .leading) // Server on the RIGHT
            }
        }
        .padding(.horizontal)
    }
    func UserMessageRow(text: String, image: String) -> some View {
        MessageRow(text: text, image: image, bgColor: colorScheme == .light ? Color.blue : Color.gray.opacity(0.5))
    }

    func LangMessageRow(text: String, image: String, responseError: String? = nil, showDotLoading: Bool) -> some View {
        MessageRow(text: message.responseText, image: image, bgColor: colorScheme == .light ? Color.gray.opacity(0.2) : Color.blue, responseError: responseError, showDotLoading: message.responseText.isEmpty)
    }

    
    func MessageRow(text: String, image: String, bgColor: Color, responseError: String? = nil, showDotLoading: Bool = false) -> some View {
        HStack(spacing: 12) {
            MessageImage(image: image)
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                if text.isEmpty && showDotLoading {
                    DotLoadingView()
                } else {
                    Text(text)
                        .font(.system(size: 16))
                        .foregroundColor(bgColor == Color.blue ? .white : .primary)
                        .padding(10)
                        .background(bgColor)
                        .cornerRadius(16)

                    if let error = responseError {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 10)
                    }
                }
            }
        }
    }


    func DotLoadingView() -> some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { _ in
                Circle().frame(width: 6, height: 6).foregroundColor(.gray)
            }
        }
    }
}

struct MessageImage: View {
    var image: String

    var body: some View {
        Group {
            if image.hasPrefix("http"), let url = URL(string: image) {
                AsyncImage(url: url, content: { image in
                    image.resizable()
                }, placeholder: {
                    ProgressView()
                })
            } else {
                Image(image).resizable()
            }
        }
        .frame(width: 25, height: 25)
        .cornerRadius(12.5)
    }
}



    
//    // Moved the preview outside of the main struct.
//    struct MessageRowView_Previews: PreviewProvider {
//        static let message = MessageRow(isInteractingwithModel: false, sendImage: "profile", sendText: "How old am i?", responseImage: "openai", responseText: "30!!!!")
//
//        static let message2 = MessageRow(isInteractingwithModel: true, sendImage: "profile", sendText: "How old am i?", responseImage: "openai", responseText: "30!!!!")
//
//        static var previews: some View {
//            NavigationView {
//                ScrollView {
//                    MessageRowView(message: message, retryCallback: { _ in })
//                        .frame(width: 400)
//                        .previewLayout(.sizeThatFits)
//                }
//            }
//        }
//    }
//}

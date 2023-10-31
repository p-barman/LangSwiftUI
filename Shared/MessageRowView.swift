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
            } 
            else if (message.imageUrl != nil){
                LangMessageImage(url: message.imageUrl ?? "profile")
            }
        
            else {
                LangMessageRow(text: message.responseText ?? "", image: message.responseImage, responseError: message.responseError, showDotLoading: message.isInteractingwithModel || message.responseText.isEmpty)
                    .frame(maxWidth: .infinity, alignment: .leading) // Server on the RIGHT
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    func UserMessageRow(text: String, image: String) -> some View {
        MessageRow(text: text, image: image, bgColor: colorScheme == .light ? Color.blue : Color.gray.opacity(0.5))
    }

    func LangMessageRow(text: String, image: String, responseError: String? = nil, showDotLoading: Bool) -> some View {
        //not image is the profile pic
        MessageRow(text: message.responseText, image: image, bgColor: colorScheme == .light ? Color.gray.opacity(0.2) : Color.blue, responseError: responseError, showDotLoading: message.responseText.isEmpty)
    }
    func LangMessageImage(url: String) -> some View {
        ImageView(urlString: url)
        
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
                    URLTextView(text: text, bgColor: bgColor)
                }

                if let error = responseError {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 10)
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


//struct LinkTextView: UIViewRepresentable {
//    var attributedText: NSAttributedString
//
//    func makeUIView(context: Context) -> UITextView {
//        let textView = UITextView()
//
//        // Set an intrinsic content size
//        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
//        textView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
//
//        textView.isScrollEnabled = false // Disable scrolling
//        textView.isEditable = false     // Ensure it's not editable
//        textView.textContainer.lineFragmentPadding = 0 // Removes default padding
//        textView.textContainerInset = .zero // Ensure there's no default text inset
//        textView.dataDetectorTypes = .link
//        textView.isUserInteractionEnabled = true
//        textView.isSelectable = true
//
//        return textView
//    }
//
//    func updateUIView(_ uiView: UITextView, context: Context) {
//        uiView.attributedText = attributedText
//    }
//}

//struct AttributedText: UIViewRepresentable {
//    var attributedString: NSAttributedString
//
//    func makeUIView(context: Context) -> UITextView {
//        let textView = UITextView()
//        textView.isEditable = false
//        textView.isScrollEnabled = false
//        textView.dataDetectorTypes = .all
//        textView.delegate = context.coordinator
//        return textView
//    }
//
//    func updateUIView(_ uiView: UITextView, context: Context) {
//        uiView.attributedText = attributedString
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    class Coordinator: NSObject, UITextViewDelegate {
//        var parent: AttributedText
//
//        init(_ parent: AttributedText) {
//            self.parent = parent
//        }
//
//        // Implement UITextViewDelegate methods if needed
//    }
//}
import SwiftUI
import UIKit

struct URLTextView: View {
    let text: String
    let bgColor: Color

    var body: some View {
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
           let match = detector.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
           let range = Range(match.range, in: text),
           let url = URL(string: String(text[range])) {
            
            let urlText = text[range]
            let preUrlText = text[text.startIndex..<range.lowerBound]
            let postUrlText = text[range.upperBound..<text.endIndex]

            return AnyView(
                VStack {
                    Text(String(preUrlText))
                        .font(.system(size: 16))
                        .foregroundColor(bgColor == Color.blue ? .white : .primary)
                    +
                       Text(LocalizedStringKey(String(urlText)))
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                                .underline()
                    +
                    Text(String(postUrlText))
                        .font(.system(size: 16))
                        .foregroundColor(bgColor == Color.blue ? .white : .primary)
                }
            )
        } else {
            return AnyView(
                Text(text)
                    .font(.system(size: 16))
                    .foregroundColor(bgColor == Color.blue ? .white : .primary)
                    .padding(10)
                    .background(bgColor)
                    .cornerRadius(16)
            )
        }
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

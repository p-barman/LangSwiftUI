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
                LangMessageImage(url: message.imageUrl ?? "profile", image: "langicon", response_image: message.imageUrl!, responseError: message.responseError, showDotLoading: message.isInteractingwithModel)
            }
        
            else { //non image row
                LangMessageRow(text: message.responseText ?? "", image:  "langicon", responseError: message.responseError, showDotLoading: message.isInteractingwithModel || message.responseText.isEmpty)
                    .id(UUID()) // force redraw?
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
    func LangMessageImage(url: String, image: String, response_image: String, responseError: String? = nil, showDotLoading: Bool) -> some View {
        MessageRow(text: message.responseText, response_image: response_image, image: image, bgColor: colorScheme == .light ? Color.gray.opacity(0.2) : Color.blue, responseError: responseError, showDotLoading: message.responseText.isEmpty)
        
    }

    
    func MessageRow(text: String, response_image: String? = nil, image: String, bgColor: Color, responseError: String? = nil, showDotLoading: Bool = false) -> some View {
        HStack(spacing: 12) {
            MessageImage(image: image)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            if let imageResponse = response_image {
                ImageView(urlString: imageResponse)
             
                    // Adjust frame as needed
            }
            else {
                VStack(alignment: .leading, spacing: 6) {
                    if text.isEmpty && showDotLoading && response_image == nil{
                        DotLoadingView()
                    } else {
                        URLTextView(text: text, bgColor: bgColor)
                    }
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
            LottieView(name: "typing", loopMode: .loop)
                .frame(width: 50, height: 100)  // Set the width and height of the LottieView
            Spacer()  // This will push the LottieView to the left
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
struct URLTextView: View {
    let text: String
    let bgColor: Color
    @StateObject private var clipboardManager = ClipboardManager()

    private func processText() -> [(String, Bool)] {
        var processedText = text

        // Regular expression to find Markdown link syntax with optional period
        let markdownLinkRegex = "\\[([^\\[]+)\\]\\(([^)]+)\\)\\.?"

        // Replace Markdown link syntax with just the URL and remove any trailing period
        if let regex = try? NSRegularExpression(pattern: markdownLinkRegex, options: []) {
            let nsString = NSString(string: text)
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            // Replace in reverse order to not mess up the indices
            for match in matches.reversed() {
                if match.numberOfRanges == 3 {
                    let urlRange = match.range(at: 2) // Range of the URL
                    let fullMatchRange = match.range(at: 0) // Range of the full Markdown link syntax including the period
                    if let substringRange = Range(urlRange, in: text) {
                        let url = String(text[substringRange])
                        processedText = processedText.replacingOccurrences(of: nsString.substring(with: fullMatchRange), with: url)
                    }
                }
            }
        }

        // Now that we've removed Markdown and potential trailing periods, we can find and process URLs as before
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return [(processedText, false)]
        }

        let matches = detector.matches(in: processedText, options: [], range: NSRange(location: 0, length: processedText.utf16.count))
        var segments: [(String, Bool)] = []
        var lastIndex = processedText.startIndex

        for match in matches {
            guard let range = Range(match.range, in: processedText) else { continue }
            let preRangeText = String(processedText[lastIndex..<range.lowerBound])
            if !preRangeText.isEmpty {
                segments.append((preRangeText, false))
            }
            let url = String(processedText[range])
            segments.append((url, true))
            lastIndex = range.upperBound
        }

        // Add any text after the last URL
        let remainingText = String(processedText[lastIndex..<processedText.endIndex])
        if !remainingText.isEmpty {
            segments.append((remainingText, false))
        }

        return segments
    }



    var body: some View {
            Group {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(processText(), id: \.0) { segment in
                        if segment.1 {
                            // This is a URL
                            Link(destination: URL(string: segment.0)!) {
                                Text(segment.0)
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                    .underline()
                            }
                        } else {
                            // This is regular text
                            Text(segment.0)
                                .font(.system(size: 16))
                                .foregroundColor(bgColor == Color.blue ? .white : .primary)
                        }
                    }
                }
                .padding(10)
                .background(bgColor)
                .cornerRadius(16)
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                clipboardManager.copyToClipboard(text: text)
            }
            .overlay(alignment: .center) {
                if clipboardManager.showingCopyConfirmation {
                    ConfirmationView()
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(1) // Ensure it's above other views
                }
            }
        }
    }


import SwiftUI
import UIKit

class ClipboardManager: ObservableObject {
    @Published var showingCopyConfirmation = false
    
    func copyToClipboard(text: String) {
        UIPasteboard.general.string = text
        showingCopyConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Adjust time as needed
            self.showingCopyConfirmation = false
        }
    }
}

struct ConfirmationView: View {
    var body: some View {
        Text("Copied to clipboard")
            .font(.system(size: 14))
            .foregroundColor(.white)
            .padding(8)
            .background(Color.black.opacity(0.75))
            .cornerRadius(8)
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

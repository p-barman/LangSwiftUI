//
//  ContentView.swift
//  XCAChatGPT
//
//  Created by Alfian Losari on 01/02/23.
//

import Foundation
import SwiftUI
import StoreKit

struct ContentView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.requestReview) var requestReview
    @ObservedObject var vm = ViewModel(api: ChatUAPI(apiKey: "PASS IN YOUR API KEY"))

//    @StateObject var vm = ViewModel(api: ChatUAPI(apiKey: "PASS IN YOUR API KEY"))
//    @StateObject var websocketVM = WebSocketViewModel.websocketVMweb

    @State private var showSettingsView: Bool = false

    @FocusState var isTextFieldFocused: Bool
    
    
    var body: some View {
        NavigationView {
            chatListView
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        TypingText(title: "LANG")
                    }
                }
                .navigationBarItems(trailing:
                                HStack(spacing: 15) {
                                    Button(action: {
                                        // Clear chat action
                                        vm.clearChat()
                                    }) {
                                        Image(systemName: "eraser") // Assuming you're using SF Symbols, otherwise replace with your asset name
                                            .padding(5)
                                            .foregroundColor(.gray)
                                            .cornerRadius(5)
                                    }
                    SettingsViewButton(showSettings: $showSettingsView)
                    }
                )
                .fullScreenCover(isPresented: $showSettingsView) {
                    NavigationView {
                        SettingsView(showSettings: $showSettingsView, viewModel: vm)
                    }
                }
        }
    }
    
    
    var chatListView: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // If messages is empty, display the ZStack
                        if vm.messages.isEmpty {
                            ZStack {
                                Image("langicon")
                                    .resizable()
                                    .frame(maxWidth: 100, maxHeight: 100)
                                    .clipShape(Circle())
                                LottieView(name: "loading", loopMode: .loop)
                                    .frame(width: 250, height: 150)
                            }
                            .frame(width: 150, height: 100)
                        } else {
                            // Otherwise, display the messages
                            ForEach(vm.messages) { message in
                                MessageRowView(message: message) { message in
                                    Task { @MainActor in
                                        await vm.retry(message: message)
                                    }
                                }
                            }
                        }
                    }
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                }
                Divider()
                bottomView(image: "profile", proxy: proxy)
                Spacer()
            }
            // scroll to the bottom on change of last response message
            .onChange(of: vm.messages.last?.responseText) { _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: vm.isEndOfStream) { endOfStream in
                if endOfStream {
                    vm.isEndOfStream = false
                    // Trigger the API call here, passing the responseText from the last message
                    let lastResponseText = vm.messages.last?.responseText ?? ""
                    let lastUserMessage = vm.messages[vm.messages.count - 2].sendText ?? "" // Assuming user message is one before the last
                    Task {
                        await vm.fetchSuggestedQuestions(lastUserMessage: lastResponseText)
                        
                    }
                    
                }
            }

        }
        .background(colorScheme == .light ? .white : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5))
    }

    

     
    // user input declared
    func bottomView(image: String, proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 0 ) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(vm.suggested_user_inputs, id: \.self) { suggestion in
                        Button(action: {
                            vm.inputMessage = suggestion
                        }) {
                            Text(suggestion)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 40)
            
            HStack(alignment: .top, spacing: 8) {
                if image.hasPrefix("http"), let url = URL(string: image) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .frame(width: 30, height: 30)
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Image(image)
                        .resizable()
                        .frame(width: 30, height: 30)
                        .cornerRadius(5)
                        
                }
                TextField("Send Message", text: $vm.inputMessage, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                    .disabled(vm.isInteractingWithModel)
                
                if vm.isInteractingWithModel {
                    DotLoadingView().frame(width: 60, height:20)
                } else {
                    Button {
                        Task { @MainActor in
                            isTextFieldFocused = false
                            scrollToBottom(proxy: proxy) // helps scrolling to the last message
                            //send the message
                            await vm.sendTapped()
                        }
                        
                    } label: {
                        Image(systemName: "paperplane.circle.fill")
                            .rotationEffect(.degrees(45))
                            .font(.system(size:30))
                    }
                    .disabled(vm.inputMessage
                        .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
                
        }
    }
            //        }
            //        HStack(alignment: .top, spacing: 8) {
            //            if image.hasPrefix("http"), let url = URL(string: image) {
            //                AsyncImage(url: url) { image in
            //                    image
            //                        .resizable()
            //                        .frame(width: 30, height: 30)
            //                } placeholder: {
            //                    ProgressView()
            //                }
            //
            //            } else {
            //                Image(image)
            //                    .resizable()
            //                    .frame(width: 30, height: 30)
            //            }
            //            TextField("Send Message", text: $vm.inputMessage, axis: .vertical)
            //                .textFieldStyle(.roundedBorder)
            //                .focused($isTextFieldFocused)
            //                .disabled(vm.isInteractingwithModel)
            //
            //            if vm.isInteractingwithModel {
            //                DotLoadingView().frame(width: 60, height:30)
            //            } else {
            //                Button {
            //                    Task { @MainActor in
            //                        isTextFieldFocused = false
            //                        scrollToBottom(proxy: proxy) // helps scrolling to the last message
            //                        //send the message
            //                        await vm.sendTapped()
            //                    }
            //
            //                } label: {
            //                    Image(systemName: "paperplane.circle.fill")
            //                        .rotationEffect(.degrees(45))
            //                        .font(.system(size:30))
            //                }
            //                .disabled(vm.inputMessage
            //                    .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            //            }
            ////            TextField("Send message", text: "", axis: .vertical)
            ////               is Carly bar model.autocorrectionDisabled()
            //        }
            //        .padding(.horizontal, 16)
            //        .padding(.top, 12)
            //    }
        
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let id = vm.messages.last?.id else { return }
        proxy.scrollTo(id, anchor: .bottomTrailing)
    }
}
//    var body: some View {
//        VStack {
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundColor(.accentColor)
//            Text("Hello World")
//        }
//        .padding()
//        .onAppear{
//            Task{
//                let api = ChatUAPI(apiKey: "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")
//                do {
//                    let stream = try await api.sendMessageStream(text: "Who is James Bond?")
//                    for try await line in stream {
//                        print(line)
//                    }
////                    let text = try await api.sendMessage("who is James Bond?")
////                    print(text)
//                } catch {
//                    print(error.localizedDescription)
//                    print(error)
//                }
//            }
//
//        }
//    }

// for settings view or chatlist View navigationLink

enum ActiveView: Hashable {
    case none
    case settings
}

// For the nav title to be typed out animation

struct TypingText: View {
    let title: String
    @State private var displayedCharactersCount: Int = 0
    
    var body: some View {
        Text(String(title.prefix(displayedCharactersCount)))
            .bold() // This will make the text bold
            .font(.system(size: 24))
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                    if displayedCharactersCount < title.count {
                        displayedCharactersCount += 1
                    } else {
                        timer.invalidate()
                    }
                }
            }
    }
}


struct ContentView_previews: PreviewProvider {
    static var previews: some View {
        ContentView( vm: ViewModel(api: ChatUAPI(apiKey: "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")))
    }
}

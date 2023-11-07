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
    @ObservedObject var vm = ViewModel.shared // Use the shared instance

    @ObservedObject var paywallManager: PaywallManager
    
//    @State var numDailyMessagesAboveMax = False
//    @StateObject private var messageTracker = MessageTracker()


    @StateObject private var messageTracker = MessageTracker()
    @State private var nextMessageDateText: String = ""
    

    @State private var showSettingsView: Bool = false

    @FocusState var isTextFieldFocused: Bool

    
    var body: some View {
        
        NavigationView {
            if messageTracker.numDailyMessagesAboveMax, let nextResetDate = messageTracker.nextResetDate {
                VStack(alignment: .center) {
                                          Text("Temporary message limit exceeded.")
                                              .multilineTextAlignment(.center) // Center the text within the VStack
                                          Text("You can send messages again after \(nextResetDate, formatter: Self.resetDateFormatter) by tapping on this text area")
                                              .multilineTextAlignment(.center) // Center the text within the VStack
                                          Text("\n\nFor immediate access or concerns please email:")
                                              .multilineTextAlignment(.center) // Center the text within the VStack
                                          Text("team@langwallet.ai")
                                              .multilineTextAlignment(.center) // Center the text within the VStack
                                      }
                                      .frame(maxWidth: .infinity)
                            .onTapGesture {
                                messageTracker.objectWillChange.send() // Inform SwiftUI that an update will happen
                                messageTracker.updateResetTime() // Attempt to update the reset time
                                
                            }
                        }

            VStack {
                           if colorScheme == .light {
                               Divider()
                                   .padding(.top, -50)
                                   .frame(height: 1)
                           }
                           chatListView
            }.onAppear(
                perform: {
                    messageTracker.resetCountIfNeeded()
                }
                )
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
        .navigationViewStyle(StackNavigationViewStyle())
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
                                    .padding(.top, 20)
                                LottieView(name: "loading", loopMode: .loop)
                                    .frame(width: 250, height: 150)
                            }
                            .frame(width: 150, height: 100)
                            .onTapGesture {
                                                       requestReview() // This will trigger the review request
                                                   }
                            
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
    
    private static var resetDateFormatter: DateFormatter {
           let formatter = DateFormatter()
           formatter.dateStyle = .none
           formatter.timeStyle = .short
           return formatter
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
                
                Button {
                    Task { @MainActor in
                        isTextFieldFocused = false
                        scrollToBottom(proxy: proxy) // helps scrolling to the last message
                        //send the message
                        await vm.sendTapped()
                        paywallManager.messagesSent += 1
                        messageTracker.messageSent()
                    }
                } label: {
                    Image(systemName: "paperplane.circle.fill")
                        .rotationEffect(.degrees(45))
                        .font(.system(size:30))
                }
                .disabled(vm.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isInteractingWithModel)

            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
                
        }
    }

        
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let id = vm.messages.last?.id else { return }
        proxy.scrollTo(id, anchor: .bottomTrailing)
    }
    
    
 
}




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
//            .fontWidth(width: 5)
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


class MessageTracker: ObservableObject {
    @Published var numDailyMessagesAboveMax: Bool = false

    private let messageCountKey = "dailyMessageCount"
    private let resetDateKey = "resetDate"

    private var userDefaults: UserDefaults { UserDefaults.standard }
    
    var nextResetDate: Date? {
           guard let resetDate = userDefaults.object(forKey: resetDateKey) as? Date else {
               return nil
           }
           return resetDate.addingTimeInterval(Double(Constants.maxMessagesResetHours) * 60.0 * 60.0)
       }
    // Call this method whenever a message is sent
    func messageSent() {
        let currentCount = userDefaults.integer(forKey: messageCountKey)
        let updatedCount = currentCount + 1
        
        userDefaults.set(updatedCount, forKey: messageCountKey)
        
        if updatedCount > Constants.maxMessages {
            numDailyMessagesAboveMax = true
        }
        
        // Check if we need to reset the count for a new period as defined in Constants
        resetCountIfNeeded()
    }
    
    // Reset message count if 24 hours have passed
    func resetCountIfNeeded() {
        guard let resetDate = userDefaults.object(forKey: resetDateKey) as? Date else {
            // If we don't have a reset date, set it now
            userDefaults.set(Date(), forKey: resetDateKey)
            return
        }
        
        // Check if the specified hours have passed since the reset date
        if Date().timeIntervalSince(resetDate) > Double(Constants.maxMessagesResetHours) * 60.0 * 60.0 {
            userDefaults.set(0, forKey: messageCountKey) // Reset count
            userDefaults.set(Date(), forKey: resetDateKey) // Update reset date
            numDailyMessagesAboveMax = false // Reset daily messages check
        }
    }
    func updateResetTime() {
            resetCountIfNeeded() // This will check and update the reset time if necessary
        }
    
    init() {
         // Check if the daily message limit is exceeded when the tracker is initialized
         let currentCount = userDefaults.integer(forKey: messageCountKey)
         numDailyMessagesAboveMax = currentCount > Constants.maxMessages
         resetCountIfNeeded()
     }
}



//struct ContentView_previews: PreviewProvider {
//    static var previews: some View {
//        ContentView( vm: ViewModel(api: ChatUAPI(apiKey: "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")))
//    }
//}



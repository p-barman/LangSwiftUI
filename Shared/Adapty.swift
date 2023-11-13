//
//  Adapty.swift
//  XCAChatGPT
//
//  Created by P on 2023-10-25.
//

import Foundation
import SwiftUI
import Adapty
import StoreKit
import RevenueCat




struct Paywall: View {
    @Environment(\.openURL) var openURL
    @State private var selectedPackage: Package?
    @State private var selectedProduct: SKProduct?
    @State private var waitingForApplePurchase = false
    @State private var selectedRestore: Bool?
    @Environment(\.requestReview) var requestReview
    
    //subscription:
    @State private var tokenTextClickCount: Int = 0
    @State private var showBetaSubscription: Bool = false
    
    @State private var numProductsToShow: Int = 4
    
    @EnvironmentObject var paywallManager: PaywallManager

    @Binding var isPaywallPresented: Bool
    
    @State var currentOffering: Offering?
    @State private var goUnlimitedClicked = false
    @State private var hideLottie = false
    
    @State var paywall: AdaptyPaywall?
    @State var products: [AdaptyProduct]?
    @State var iterableProducts: [SKProduct]?
    
    @EnvironmentObject var userStateModel: UserStateModel
    
    var body: some View {
        VStack (alignment: .center, spacing: 1) {
            Text("You've used up your lang tokens!")
                .bold()
                .foregroundColor(.blue)
                .font(.system(size: 14))
                .padding(.bottom, 23)
                .padding(.top, 15)
            
            Text("Go Unlimited!")
                .bold()
                .font(.largeTitle)
                .foregroundColor(.purple)
                .multilineTextAlignment(.center)
                .padding(.bottom, 25)
                .onTapGesture{
                    print("Go Unlimited! clicked")
                    self.goUnlimitedClicked.toggle()
                    self.hideLottie.toggle()
                    self.tokenTextClickCount += 1
                            if self.tokenTextClickCount >= 20 {
                                self.showBetaSubscription = true
                                self.numProductsToShow = 4
                            }
                }
                .onLongPressGesture(minimumDuration: 6, pressing: { pressing in
                    if pressing {
                        // This will trigger as soon as the long press starts
                    } else {
                        // This will trigger when the long press ends, regardless of duration
                    }
                }) {
                    // This is the action to perform after the long press has been held for 8 seconds
                    print("Go unlimited held for 8s")
                    paywallManager.shouldShowPaywall = false
                    paywallManager.incrementMax()
                    
                    // Display the review request
                    requestReview()
                }
            
            VStack (spacing: 7) {
                HStack {
                    Image(systemName: "shareplay")
                    Text("Priority responses")
                        .font(.system(size: 20))
                }
                HStack {
                    Image(systemName: "checkmark.icloud")
                    Text("Premium features")
                        .font(.system(size: 20))
                }
                .padding(.bottom, 1)
            }
            
            Spacer().frame(height:10 )
            
            ZStack {
                if self.selectedPackage != nil || ((self.goUnlimitedClicked || currentOffering == nil) && !self.hideLottie) {
                    Image("langicon")
                        .frame(maxWidth: 100, maxHeight: 100)
                        .clipShape(RoundedRectangle(cornerRadius:20))
                    LottieView(name: "loading", loopMode: .loop)
                        .frame(width: 250, height: 150)
                }
            }
            .frame(width: 150, height: 100)
            .padding(.bottom, 40)
            
            if self.waitingForApplePurchase {
                ProgressView()
                Spacer().frame(height:15)
            }
            
            VStack  {
                if let availableProducts = iterableProducts {
                    let productsToShow: [SKProduct] = showBetaSubscription ? availableProducts : availableProducts.dropLast()
                        ForEach(productsToShow, id: \.productIdentifier) { product in
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .frame(maxWidth: 270, maxHeight: 60)
                                    .foregroundColor(.blue)
                                    .shadow(color: .gray, radius: 3)
                                
                                Text("\(productBtnDescription(str: product.localizedDescription, product: product))")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18))
                            }
                            .buttonStyle(GrowingButton())
                            .padding(.bottom, 5)
                            
                            .opacity(90)
                            .scaleEffect(self.selectedProduct == product ? 1.1 : 1)
                            .shadow(radius: self.selectedProduct == product ? 3 : 0)
                            .onTapGesture {
                                self.waitingForApplePurchase = true
                                self.selectedProduct = product
                                self.selectedRestore = false
                                
                                let productId : String = product.productIdentifier
                                let aProduct: AdaptyProduct = self.getProductWith(productId: productId, totalNumProducts: self.numProductsToShow)!
                                
                                DispatchQueue.global(qos: .userInitiated).async {
                                    Adapty.makePurchase(product: aProduct as! AdaptyPaywallProduct) { result in
                                        switch result {
                                        case let .success(info):
                                               if info.profile.accessLevels["premium"]?.isActive ?? false {
                                                   print("Successful purchase of —— ", aProduct, "what's profile? ", info.profile)
                                                   userStateModel.isSubscriptionActive = true
                                                   paywallManager.shouldShowPaywall = false
                                            }
                                            self.waitingForApplePurchase = false
                                            
                                        case let .failure(error):
                                            print(error)
                                            self.waitingForApplePurchase = false
                                            self.selectedProduct = nil
                                        }
                                    }

                                }
                            }
                        }
                    
                    Spacer().frame(height: 30)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .frame(maxWidth: 200, maxHeight: 30)
                            .foregroundColor(Color(red: 44/255, green: 47/255, blue: 56/255))
                            .shadow(color: .gray, radius: 3)
                        
                        Text("Subscribed? Restore")
                            .foregroundColor(.white)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(GrowingButton())
                    .padding(.bottom, 5)
                    .padding(.bottom, 1)
                    .opacity(90)
                    .scaleEffect(self.selectedRestore == true ? 1.1 : 1)
                    .onTapGesture {
                        self.selectedRestore = true
                        self.selectedProduct = nil
                        Adapty.restorePurchases({ (result) in
                            switch result {
                            case let .success(profile):
                                if profile.accessLevels["premium"]?.isActive ?? false {
                                    print("Successful subscription restored. profile: ", profile)
                                    userStateModel.isSubscriptionActive = true
                                }
                                else {
                                    print("Subscription restore NOT successful. profile: ", profile)
                                    userStateModel.isSubscriptionActive = false
                                }
                                
                            case let .failure(error):
                                print("failed to restore purchases", error)
                            }
                        })
                    }
                }
            }
            
            Spacer().frame(height: 15)
            
            HStack {
                HStack {
                    Button(action: {
                        openURL(URL(string: "https://docs.google.com/document/d/e/2PACX-1vRhzZ8BrOkmZ7NUWF80xbAu-Pzn0vDxnJDrfcJVmovaUJ09Ta2cdb2Eq6Wfu-XclI--Yfk-w90knaQx/pub")!)
                    }) {
                        Text("Privacy Policy")
                            .font(.system(size: 11))
                            .frame(maxWidth: 100, maxHeight: 6)
                            .zIndex(-1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 90, height: 6)
                    .padding([.leading], 5)
                    .zIndex(-1)
                }
                
                HStack {
                    Button(action: {
                        openURL(URL(string: "https://docs.google.com/document/d/e/2PACX-1vQnpEpthNFVto9C-7M741a4EtHWRjrAsOY98I728zCRg5Ix1CFP4VUr9HlCDJkmlziYg6fPB3jrdyed/pub")!)
                    }) {
                        Text("Terms of Use")
                            .font(.system(size: 11))
                            .frame(maxWidth: 100, maxHeight: 6)
                            .zIndex(-1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 90, height: 6)
                    .padding([.leading], 5)
                    .zIndex(-1)
                }
            }
            .task {
                do {
                    await Adapty.getPaywall("main") { result in
                        switch result {
                        case let .success(paywall):
                            print("paywall", paywall)
                            self.paywall = paywall
                            
                            Adapty.getPaywallProducts(paywall: paywall) { result in
                                switch result {
                                case let .success(products):
                                    self.products = products
                                    self.iterableProducts = (products.map { $0.skProduct })
                                    let x: SKProduct = products[0].skProduct
                                    print("x", x.localizedDescription)
                                    print("x", x.price)
                                    
                                case let .failure(error): break
                                }
                            }
                        case let .failure(error): break
                        }
                    }
                } catch {
                    print(error)
                }
            }
            .onAppear {
                
            }
        }
    }
    
    func getProductWith(productId: String, totalNumProducts: Int) -> AdaptyProduct? {
        for index in 0..<totalNumProducts {
            if (self.products![index].vendorProductId == productId) {
                return self.products![index]
            }
//            else {
//                return self.products![1]
//            }
        }
        return self.products![3]
    }
}

struct GrowingButton: ButtonStyle
{
    // required method to conform to ButtonStyle protocol
    func makeBody(configuration: Self.Configuration) -> some View
    {
        GrowingButtonView(configuration: configuration)
    }
    
    struct GrowingButtonView: View
    {
        let configuration: GrowingButton.Configuration
        
        var body: some View
        {
            configuration.label
                .padding(.horizontal, 50)
                .frame(width:60)
                .background(.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .scaleEffect(configuration.isPressed ? 1.2 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
}

extension Package {
    func terms(for package: Package) -> String {
        if let intro = package.storeProduct.introductoryDiscount {
            if intro.price == 0 {
                return "\(intro.subscriptionPeriod.periodTitle) free trial, then \(package.storeProduct.localizedPriceString)/\(package.storeProduct.subscriptionPeriod!.periodTitle)"
            } else {
                return "\(package.storeProduct.localizedPriceString)/\(package.storeProduct.subscriptionPeriod!.periodTitle)"
            }
        } else {
            return "\(package.storeProduct.localizedPriceString)/\(package.storeProduct.subscriptionPeriod!.periodTitle)"
        }
    }
}

extension SubscriptionPeriod {
    var durationTitle: String {
        switch self.unit {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return "Unknown"
        }
    }
    
    var periodTitle: String {
        let periodString = "\(self.value) \(self.durationTitle)"
        let pluralized = self.value > 1 ?  periodString + "s" : periodString
        return pluralized
    }
}

func productBtnDescription(str: String, product: SKProduct) -> String {
    if str == "" {
        switch product.productIdentifier {
        case "langai_25999_1y":
            return " $\(product.price)/year"
        case "langai_2999_1m":
            return "$\(product.price)/month"
        case "langai_999_1w":
            return "$\(product.price)/week"
        case "langai_199_1w":
            return "$\(product.price)/week"
        default:
            return "\(product.price) - click for duration"
        }
    }
    
    if let components = try? str.components(separatedBy: " - ")  {
        let timeComponents = components[1].components(separatedBy: ", ")
        if timeComponents.count == 2 && timeComponents[0].contains("year") {
            return "\(timeComponents[0]) at $\(product.price)"
        } else {
            do {
                var title = "\(components[1].components(separatedBy: ", ")[0]) at $\(product.price)" ?? nil
                if title == nil {
                    return "\(product.price) - click for duration"
                }
                return title!
            } catch {
                print("error getting title - will return click for duration")
            }
        }
    } else {
        return "click for price"
    }
}







//struct Paywall_View: PreviewProvider {
//    static var previews: some View {
//        let userState = UserStateModel()
//        userState.isSubscriptionActive = false
//        return PaywallView(userState: userState)
//    }
//}

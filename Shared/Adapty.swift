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


class UserStateModel: ObservableObject {
    
    @Published var isSubscriptionActive = false
    @Published var agreedToTerms: Bool = (UserDefaults.standard.bool(forKey: "agreedToTerms") ?? false)
    @Published var isBackendLive: Bool = false
    
    init() {
        self.agreedToTerms = UserDefaults.standard.bool(forKey: "agreedToTerms")
        
        Adapty.getProfile { result in
            if let profile = try? result.get(),
               profile.accessLevels["premium"]?.isActive ?? false {
                
                print("this user is subscribed to ", profile.subscriptions)
                self.isSubscriptionActive = true
            }
            
        }
    }
}


//struct Paywall: View {
//    @Environment(\.openURL) var openURL
////    @State private var selectedPackage: Package?
//    @State private var selectedProduct: SKProduct?
//    @State private var waitingForApplePurchase: Bool = false
//    @State private var selectedRestore: Bool?
//
//    @Binding var isPaywallPresented: Bool
//
//    @State var currentOffering: Offering?
//    @State private var goUnlimitedClicked: Bool = false
//    @State private var hideLottie: Bool = false
//
//    @State var paywall: AdaptyPaywall?
//    @State var products: [AdaptyProduct]?
//    @State var iterableProducts: [SKProduct]?
//
//    @EnvironmentObject var userViewModel: UserStateModel
//}
//
//
//extension SubscriptionPeriod {
//    var durationTitle: String {
//        switch self.unit {
//        case .day: return "day"
//        case .week: return "week"
//        case .month: return "month"
//        case .year: return "year"
//        @unknown default: return "Unknown"
//        }
//    }
//    var periodTitle: String {
//        let periodString = "\(self.value) \(self.durationTitle)"
//        let pluralized = self.value > 1 ?  periodString + "s" : periodString
//        return pluralized
//    }
//}
//
//


struct Paywall: View {
    @Environment(\.openURL) var openURL
    @State private var selectedProduct: SKProduct?
    @State private var waitingForApplePurchase: Bool = false
    @State private var selectedRestore: Bool?
    
    @Binding var isPaywallPresented: Bool
    @State var paywall: AdaptyPaywall?
    @State var products: [AdaptyProduct]?
    @State var iterableProducts: [SKProduct]?
    
    @EnvironmentObject var userViewModel: UserStateModel
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("Available Subscriptions")
                .font(.title)
            
            //            List(iterableProducts ?? [], id: \.productIdentifier) { product in
            //                VStack(alignment: .leading) {
            //                    Text(product.localizedTitle)
            //                        .font(.headline)
            //
            //                    Text(product.localizedDescription)
            //                        .font(.subheadline)
            //                        .lineLimit(2)
            //
            //                    Text("\(product.priceLocale.currencySymbol ?? "")\(product.price.stringValue) per \(product.subscriptionPeriod?.periodTitle ?? "")")
            //                        .font(.caption)
            //
            //                    Button("Purchase") {
            //                        // handle purchase logic here
            //                        self.selectedProduct = product
            //                    }
            //                    .foregroundColor(.white)
            //                    .padding(.vertical, 10)
            //                    .padding(.horizontal, 20)
            //                    .background(Color.blue)
            //                    .cornerRadius(10)
            //                }
            //            }
            //
            //            Button("Restore Purchases") {
            //                // handle restore purchases logic here
            //                self.selectedRestore = true
            //            }
            //
            //            Spacer()
            //        }
            //        .padding()
            //        .onAppear {
            //            // Load products from Adapty
            //            loadProducts()
            //        }
            //    }
            
//            func loadProducts() {
//                // Assuming Adapty has a function to fetch paywalls and products
//                Adapty.getPaywalls { paywalls, products, error in
//                    self.paywall = paywalls?.first
//                    self.products = products
//                    self.iterableProducts = products?.compactMap { $0.skProduct }
//                }
//            }
        }
    }
}



struct Paywall_View: PreviewProvider {
    static var previews: some View {
        Paywall(isPaywallPresented: .constant(true))
    }

}

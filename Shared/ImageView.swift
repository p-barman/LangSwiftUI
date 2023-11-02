//
//  ImageView.swift
//  LangSwiftUI
//
//  Created by blake on 2023-10-31.
//

import Foundation
import SwiftUI
import UIKit

var completedApiCallForUrl: String?
var completedApiCalls = [String: Data]()

struct ImageView: View {
    @State var urlString: String?
    var body: some View {
        Group {
            if (urlString != "" && urlString != completedApiCallForUrl) {
                AsyncImage(url: URL(string: urlString!)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(10)
                            .shadow(color: .gray, radius: 5, x: 0, y: 4)
                            .transition(.opacity) // Fade-in animation
                            .animation(.easeInOut(duration: 0.5))
                    case .failure(_):
                        Text("error loading img.")
                            .font(.system(size: 20))
                            .scaledToFit()
                            .padding(.leading, 10)
                    @unknown default:
                        ProgressView()
                    }
                }
            }
            else if (urlString != "" && completedApiCalls[urlString!] != nil) {
                Image(uiImage: image_w_existing_data)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(10)
                    .shadow(color: .gray, radius: 5, x: 0, y: 4)
                    .transition(.opacity) // Fade-in animation
                    .animation(.easeInOut(duration: 0.5))
            }
            else {
                EmptyView()
            }
        }
    }

    // ... (the rest of your ImageView code remains unchanged)


    private var image: UIImage {
        do {
            let url = URL(string: urlString!)!
            let data = try Data(contentsOf: url)
            completedApiCalls[urlString!] = data
            return UIImage(data: data)!
        } catch  {
            print("error in image data fetch/opening: ",  error)
           
            let image = UIImage(named: "jan21-good-small.png")!
//            let data = UIImage.pngData(image)!
            return image
            // Handle the error here
        }

//        completedApiCallForUrl = urlString
//        completedApiCalls[urlString!] = data
//        return UIImage(data: data)!
    }
     private var image_w_existing_data: UIImage {
       let data = completedApiCalls[urlString!]!
       return UIImage(data: data)!
    }
}

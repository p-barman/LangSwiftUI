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
        if (urlString != "" && urlString != completedApiCallForUrl) {
//            AsyncImage(url: URL(string: urlString!))
            AsyncImage(url: URL(string: urlString!)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFit()
                } else if phase.error != nil {
                    Text("error loading img.")
                        .font(.system(size: 20))
                        .scaledToFit()
                } else {
                    ProgressView()
                }
            }
//            .frame(width: 200, height: 200)
        }
        else if (urlString != "" && completedApiCalls[urlString!] != nil) {
            Image(uiImage: image_w_existing_data) //not in use b/c image below is never called so completedApiCalls is never stored.
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
        else {
            EmptyView()
        }
    }
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

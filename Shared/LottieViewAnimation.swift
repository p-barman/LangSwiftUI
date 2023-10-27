//
//  LottieViewAnimation.swift
//  XCAChatGPT
//
//  Created by P on 2023-10-26.
//

import Foundation


import Foundation

import SwiftUI
import Lottie
 
struct LottieView: UIViewRepresentable {
    var name = "loading"
    var loopMode: LottieLoopMode = .repeat(4)

    func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
        let view = UIView(frame: .zero)

        let animationView = LottieAnimationView()
        animationView.animation = LottieAnimation.named(name)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        animationView.play()

        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])

        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
}


struct LottieView_Previews: PreviewProvider {
    static var previews: some View {
        LottieView()
            .frame(width: 300, height: 300) // you can adjust the frame as needed
            .background(Color.gray) // optional: just to give it a background in the preview
    }
}


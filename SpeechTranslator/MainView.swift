//
//  MainView.swift
//  SpeechTranslator
//
//  Created by Hasegawa Akito on 2022/07/18.
//  Copyright © 2022 Daniel Bolella. All rights reserved.
//

import SwiftUI
import NaturalLanguage //感情認識用



struct MainView: View {
    @ObservedObject var closedCap = ClosedCaptioning()
    
    //感情認識用
    @State private var text: String = ""
    //translationされた文字を使って感情分析を実行しsentimentに代入する
    private var degrees: Double {
        
        return performSentimentAnalysis(for: self.closedCap.translation)
    }
    private let tagger = NLTagger(tagSchemes: [.sentimentScore])
    
    @State var changeUI: Bool = false
    
//    @State var degrees = 0.0
        
    var animation: Animation {
        Animation.easeInOut(duration: 3.0)
        .repeatForever(autoreverses: false)
    }
    
    var body: some View {
        VStack {
            Image("kaigara")
                .resizable()
                .frame(width: 250.0, height: 250.0)
                .foregroundColor(.pink)
                .rotation3DEffect(.degrees(degrees), axis: (x: 0, y: 1, z: 0))
                .animation(changeUI ? animation : nil)
            
            
            Button(action: {
                changeUI = true
                
                self.closedCap.micButtonTapped()
            }) {
                Image(systemName: !self.closedCap.micEnabled ? "mic.slash" : (self.closedCap.isPlaying ? "mic.circle.fill" : "mic.circle"))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 75)
                    .padding()
            }
        }
        .onAppear {
            self.closedCap.getPermission()
        }
    }
    
    //感情スコア算出
    private func performSentimentAnalysis(for string: String) -> Double {
        tagger.string = string
        let (sentiment, _) = tagger.tag(at: string.startIndex,
                                        unit: .paragraph,
                                        scheme: .sentimentScore)
        let sentiValue_string: String = sentiment?.rawValue ?? "0"
        
        let sentiValue: Double = Double(sentiValue_string) ?? 0.0

        if (sentiValue > 0.0) {
            return 360.0
        }
        else {
            return 0.0
        }
//        print(sentiment?.rawValue ?? 0 as Any)
//        return sentiment?.rawValue ?? ""
    }
    
   
}

struct MainView_Previews: PreviewProvider {
    
    static var previews: some View {
        MainView()
    }
}

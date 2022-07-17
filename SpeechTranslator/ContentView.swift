//
//  ContentView.swift
//  SpeechTranslator
//
//  Created by Daniel Bolella on 10/9/19.
//  Copyright © 2019 Daniel Bolella. All rights reserved.
//

import SwiftUI
import NaturalLanguage //感情認識用

struct ContentView: View {
    @ObservedObject var closedCap = ClosedCaptioning()
    
    //感情認識用
    @State private var text: String = ""
    //translationされた文字を使って感情分析を実行しsentimentに代入する
    private var sentiment: String {
        return performSentimentAnalysis(for: self.closedCap.translation)
    }
    private let tagger = NLTagger(tagSchemes: [.sentimentScore])
    
    var body: some View {
        VStack {
            Text("音声認識 (日本語)")
                .foregroundColor(/*@START_MENU_TOKEN@*/.gray/*@END_MENU_TOKEN@*/)
                .padding(.top, 20.0)
            HStack {
                Text(self.closedCap.captioning)
                    .font(.body)
                    .truncationMode(.head)
                    .lineLimit(4)
            }
            .padding(.bottom, 20)
            .frame(width: 350, height: 150)
            .background(Color.red.opacity(0.25))
            
            Text("翻訳結果 (英語)")
                .foregroundColor(/*@START_MENU_TOKEN@*/.gray/*@END_MENU_TOKEN@*/)
                .padding(.top, 20.0)
            HStack {
                Text(self.closedCap.translation)
                    .font(.body)
                    .truncationMode(.head)
                    .lineLimit(4)
            }
            
            .frame(width: 350, height: 150)
            .background(Color.blue.opacity(0.25))
            
            Text("感情分析結果 (-がネガティブ、+がポジティブ)")
                .foregroundColor(/*@START_MENU_TOKEN@*/.gray/*@END_MENU_TOKEN@*/)
                .padding(.top, 20.0)
            //感情認識用
            HStack {
                Text(sentiment)
            }
            .frame(width: 350, height: 50.0)
            .background(Color.purple.opacity(0.25))
            
            Button(action: {
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
    private func performSentimentAnalysis(for string: String) -> String {
        tagger.string = string
        let (sentiment, _) = tagger.tag(at: string.startIndex,
                                        unit: .paragraph,
                                        scheme: .sentimentScore)
        return sentiment?.rawValue ?? ""
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.colorScheme, .dark)
    }
}

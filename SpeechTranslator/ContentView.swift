//
//  ContentView.swift
//  SpeechTranslator
//
//  Created by Daniel Bolella on 10/9/19.
//  Copyright © 2019 Daniel Bolella. All rights reserved.
//

import SwiftUI
import NaturalLanguage //感情認識用

import Foundation //Timer用
import Combine //Timer用

struct ContentView: View {
    @State var selectedTag:Int = 1
    var body: some View {
        TabView(selection: $selectedTag) {
            //BLE側の画面
            BLEView(selectedTag: $selectedTag)
                .tabItem {
                    Image(systemName: "app.connected.to.app.below.fill")
                    Text("BLEView")
                }.tag(1)
            
            //感情分析側の画面
            //SentiAnalyViewを設定するとプレビューエラーが出るので、仮にTextを置く。(平山以外は使わなくて良いかも)
            //Text("Tab Content 2")
            SentiAnalyView(selectedTag: $selectedTag)
                .tabItem {
                    Image(systemName: "person.wave.2.fill")
                    Text("Analytics")
                }.tag(2)
        }
         
    }
}

//BLE画面
struct BLEView: View {
    @Binding var selectedTag: Int
    @ObservedObject private var bluetooth = Bluetooth()
    @State private var editText = ""

    
    var body: some View {
        //ScrollView{
            VStack(alignment: .leading, spacing: 5) {
                HStack() {
                    Spacer()
                    Button(action: {
                        self.bluetooth.buttonPushed()
                        
                    })
                    {
                        Text(self.bluetooth.buttonText)
                            .font(.largeTitle)
                            .padding()
                            .frame(width: 200, height: 200, alignment: .center)
                            .overlay(
                                RoundedRectangle(cornerRadius: 100)
                                    .stroke(Color.blue, lineWidth: 1))
                    }
                    Spacer()
                }
                /*
                Text(self.bluetooth.stateText)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                */
                
                if self.bluetooth.CONNECTED {
                    VStack(alignment: .leading, spacing: 5) {
                        TextField("送信文字列", text: $editText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                            //Connectされてこのテキストボックスが表示されたら画面遷移
                            .onAppear{ selectedTag = 2 }
                       }
                   }
            /*
            .onAppear{
                //使用許可リクエスト等
            }
            */
        }.padding(.vertical)
    }
}

//感情分析画面
struct SentiAnalyView: View {
    
    @Binding var selectedTag: Int
    @EnvironmentObject var closedCap : ClosedCaptioning
    
    //感情認識用
    @State private var text: String = ""
    
    @State private var toggle: Bool = true
        
    //translationされた文字を使って感情分析を実行しsentimentに代入する
    var sentiment: String {
        return performSentimentAnalysis(for: self.closedCap.translation)
    }
    
    private let tagger = NLTagger(tagSchemes: [.sentimentScore])
    
    var body: some View{
        if #available(iOS 14.0, *) {
            
            VStack {
                Spacer()
                HStack {
                    Text(self.closedCap.captioning)
                        .font(.body)
                        .foregroundColor(Color.gray)
                        .truncationMode(.head)
                        .lineLimit(4)
                }
                .frame(width: 350, height: 30)
                //.hidden() //隠す
                
                HStack {
                    Text(self.closedCap.translation)
                        .font(.body)
                        .foregroundColor(Color.gray)
                        .truncationMode(.head)
                        .lineLimit(4)
                }
                .frame(width: 350, height: 30)
                //.hidden() //隠す
                
                //感情認識用
                HStack {
                    Text(sentiment)
                        .foregroundColor(Color.gray)
                }
                .frame(width: 350, height: 30)
                //.hidden() //隠す
                
                //起動したとき自動で音声認識を開始
                .onAppear{ self.closedCap.micButtonTapped() }
                                
                /*
                Button(action: {
                    self.closedCap.micButtonTapped()
                }) {
                    Image(systemName: !self.closedCap.micEnabled ? "mic.slash" : (self.closedCap.isPlaying ? "mic.circle.fill" : "mic.circle"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 75)
                        .padding()
                        //.hidden() //隠す
                }
                 */
                
            }
            // 貝の画像とアニメーション
            .overlay(
                Image("hotate2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .offset(y: toggle ? 0 : -50)
                    .animation(Animation.interactiveSpring(dampingFraction: 0.5))
            )
            .onAppear {
                self.closedCap.getPermission()
            }
            //感情スコアが変更された場合、タイマーが無ければ起動、あれば再起動
            //.onChange(of: self.closedCap.translation){ newValue in
            .onChange(of: self.sentiment){ newValue in
                /*
                　話し続けている間は再起動が掛かり続けるので、カウントは大きくならないが、
                　話が終わると再起動が掛からないためカウントが大きくなり会話の終了を検知できる
                　(ClosedCaptioning.StartTimerのプログラムを参照)
                */
                if(self.closedCap.timer == nil){
                    self.closedCap.TimerStart(0.1, Sentiment:"0")
                    toggle.toggle() //貝のアニメーション用
                }else{
                    self.closedCap.count = 0
                    self.closedCap.TimerStop()
                    self.closedCap.TimerStart(0.1, Sentiment:self.sentiment)
                    toggle.toggle() //貝のアニメーション用
                }
            }
        } else {
            // Fallback on earlier versions
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
        ContentView()
    }
}

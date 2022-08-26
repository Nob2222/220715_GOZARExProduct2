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
    //@State var selectedTag:Int
    
    //@EnvironmentObject var selectedTag: TabNo
    
    var body: some View {
        TabView(selection: $selectedTag) {
        //TabView(selection: $selectedTag.selectedTabNumber) {
            //BLE側の画面
            BLEView(selectedTag: $selectedTag)
            //BLEView()
                .tabItem {
                    Image(systemName: "app.connected.to.app.below.fill")
                    Text("BLEView")
                }.tag(1)
            
            //感情分析側の画面
            SentiAnalyView(selectedTag: $selectedTag)
            //SentiAnalyView()
                .tabItem {
                    Image(systemName: "person.wave.2.fill")
                    Text("Analytics")
                }.tag(2)
        }
        //Timer用
        .environmentObject(TimerModel())
    }
}

//BLE画面
struct BLEView: View {
    @ObservedObject private var bluetooth = Bluetooth()
    @State private var editText = ""
    @Binding var selectedTag: Int
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 5) {
                HStack() {
                    Spacer()
                    Button(action: {
                        self.bluetooth.buttonPushed()
                        
                    })
                    {
                        Text(self.bluetooth.buttonText)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 1))
                    }
                    Spacer()
                }
                Text(self.bluetooth.stateText)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                if self.bluetooth.CONNECTED {
                    
                    VStack(alignment: .leading, spacing: 5) {
                        TextField("送信文字列", text: $editText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                            //Connectされてこのテキストが表示されたら画面遷移
                            .onAppear{ selectedTag = 2 }
                        
                        HStack() {
                            Spacer()
                            Button(action: {
                                self.bluetooth.writeString(text:self.editText)
                            })
                            {
                                Text("送信する")
                                    .padding()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.red, lineWidth: 1))
                            }
                            Spacer()
                            
                        }
                        Text(self.bluetooth.resultText)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Image(uiImage: self.bluetooth.resultImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 80, alignment: .top)
            }
            .onAppear{
                //使用許可リクエスト等
            }
        }.padding(.vertical)
    }
}


//感情分析画面
struct SentiAnalyView: View {
    
    //@ObservedObject var closedCap = ClosedCaptioning()
    @EnvironmentObject var closedCap : ClosedCaptioning
    
    //感情認識用
    @State private var text: String = ""
    @Binding var selectedTag: Int
    
    //Timer用
    @EnvironmentObject var timerContorller: TimerModel
    
    //@State var txtData: TxtData = TxtData()
    
    //translationされた文字を使って感情分析を実行しsentimentに代入する
    var sentiment: String {
        return performSentimentAnalysis(for: self.closedCap.translation)
    }
    
    private let tagger = NLTagger(tagSchemes: [.sentimentScore])
    
    var body: some View{
        if #available(iOS 14.0, *) {
            VStack {
                Text("音声認識 (日本語)")
                    .foregroundColor(/*@START_MENU_TOKEN@*/.gray/*@END_MENU_TOKEN@*/)
                    .padding(.top, 20.0)
                    //.hidden() //隠す
                HStack {
                    Text(self.closedCap.captioning)
                        .font(.body)
                        .truncationMode(.head)
                        .lineLimit(4)
                        //.hidden() //隠す
                }
                .padding(.bottom, 20)
                .frame(width: 350, height: 150)
                .background(Color.red.opacity(0.25))
                //.hidden() //隠す
                
                Text("翻訳結果 (英語)")
                    .foregroundColor(/*@START_MENU_TOKEN@*/.gray/*@END_MENU_TOKEN@*/)
                    .padding(.top, 20.0)
                    //.hidden() //隠す
                HStack {
                    Text(self.closedCap.translation)
                        .font(.body)
                        .truncationMode(.head)
                        .lineLimit(4)
                        //.hidden() //隠す
                }
                
                .frame(width: 350, height: 150)
                .background(Color.blue.opacity(0.25))
                //.hidden() //隠す
                
                Text("感情分析結果 (-がネガティブ、+がポジティブ)")
                    .foregroundColor(/*@START_MENU_TOKEN@*/.gray/*@END_MENU_TOKEN@*/)
                    .padding(.top, 20.0)
                //感情認識用
                HStack {
                    Text(sentiment)
                }
                .frame(width: 350, height: 50.0)
                .background(Color.purple.opacity(0.25))
                //起動したとき自動で音声認識を開始
                .onAppear{ self.closedCap.micButtonTapped() }
                                
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
            //間違いなく値は変わっているのに、OnChangeが検出されない。
            //最初は検出されているが、タイマーによる録音再起動以降、このビューでは値の変更が検出出来なくなっている。
            .onChange(of: self.closedCap.translation){ newValue in
            //.onChange(of: self.txtData.translation){ newValue in
            //.onChange(of: self.closedCaptxt.translation){ newValue in
                //print(timerContorller.count)
                if(timerContorller.timer == nil){
                    timerContorller.start(0.1)
                }else{
                    timerContorller.count = 0
                    timerContorller.stop()
                    timerContorller.start(0.1)
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


class TimerModel: ObservableObject{
    @Published var count: Int = 0
    @Published var timer: AnyCancellable!
    
    //@EnvironmentObject var closedCap : ClosedCaptioning
    @ObservedObject var closedCap = ClosedCaptioning()
    @ObservedObject private var bluetooth = Bluetooth()
            
    // タイマーの開始
    func start(_ interval: Double = 1.0){
        //print("start Timer")

        // TimerPublisherが存在しているときは念の為処理をキャンセル
        if let _timer = timer{
            _timer.cancel()
        }

        // every -> 繰り返し頻度 / on -> タイマー処理が走るLoopを指定
        // in: -> 入力処理モードの設定 .defalut:操作系の入力と同様に処理をするらしい : .common それ以外
        // .defalutを指定していると処理が遅くなることがある
        timer = Timer.publish(every: interval, on: .main, in: .common)
            // 繰り返し処理の実行
            .autoconnect()
            //　 レシーバーが動くスレッドを指定しているのだと思われる
            //  .main -> メインスレッド(UI)　, .global() -> 別スレッド
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: ({_ in
                // 設定した時間ごとに呼ばれる
                self.count += 1
                
                if(self.count == 15){
                    print("1.5びょうたったよ")
                    self.stop()
                    
                    //録音停止
                    self.closedCap.stopRecording()
                    //self.closedCap.micButtonTapped()
                    print("録音停止します")
                    
                    //BlEの値を送信 今は100で固定
                    self.bluetooth.writeString(text: "100")
                    
                    
                    //録音再開 -> したいが出来ない
                    self.closedCap.micButtonTapped()
                    print("録音開始します！")
                    
                    
                }
                
        }))
    }

    // タイマーの停止
    func stop(){
        //print("stop Timer")
        timer?.cancel()
        timer = nil
    }

}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView().environment(\.colorScheme, .dark)
        }
    }
}

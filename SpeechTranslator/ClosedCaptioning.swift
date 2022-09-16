//
//  ClosedCaptioning.swift
//  SwiftUIClosedCaptioning
//
//  Created by Daniel Bolella on 10/9/19.
//  Copyright © 2019 Daniel Bolella. All rights reserved.
//

import Foundation
import Speech
import Firebase
import SwiftUI

import Combine //Timer用

class ClosedCaptioning: ObservableObject {
        
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja_JP"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
        
    @Published var captioning: String = "なにか話しかけてください"
    @Published var translation: String = "-"
    @Published var isPlaying: Bool = false
    @Published var micEnabled: Bool = false
    
    //Timer用
    @Published var count: Int = 0
    @Published var timer: AnyCancellable!
        
    private let translator: Translator
    
    init (){
        let options = TranslatorOptions(sourceLanguage: .ja, targetLanguage: .en)
        translator = NaturalLanguage.naturalLanguage().translator(options: options)
        translator.downloadModelIfNeeded { (error) in
            guard error == nil else { return }
            self.micEnabled = true
        }
    }
    
    //Thanks to https://developer.apple.com/documentation/speech/recognizing_speech_in_live_audio
    func startRecording() throws {
        
        // 前のタスクが実行中であれば、それをキャンセルする。
        recognitionTask?.cancel()
        self.recognitionTask = nil
        
        // アプリのオーディオセッションを設定する。
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode

        // 音声認識リクエストを作成し、設定する。
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true
        
        /*
        // 音声認識データを端末に残す
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
         */
        
        // 音声認識セッションの認識タスクを作成します。
        // タスクをキャンセルできるように、リファレンスを保持しておく。
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // テキストビューを結果で更新します。
                self.captioning = result.bestTranscription.formattedString
                print("ClosedCap-Class:Captioning: \(self.captioning)")
                
                self.translator.translate(result.bestTranscription.formattedString) { (translatedText, error) in
                    guard error == nil,
                        let translatedText = translatedText
                        else { return }
                    
                    self.translation = translatedText
                    print("ClosedCap-Class:translation: \(self.translation)")
                    
                }
                self.translate(text: result.bestTranscription.formattedString)
                isFinal = result.isFinal
                print("ClosedCap-Class:Text \(result.bestTranscription.formattedString)")
                
            }
            
            if error != nil || isFinal {
                // 問題がある場合は、音声認識を停止します。
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.isPlaying = false
            }
        }

        // マイク入力を設定する。
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }


    func stopRecording(){
        self.recognitionTask?.cancel()
        self.recognitionTask?.finish()
        self.recognitionRequest?.endAudio()
        self.recognitionRequest = nil
        self.recognitionTask = nil
        self.audioEngine.stop()
        self.isPlaying = false
        audioEngine.inputNode.removeTap(onBus: 0)
        
        //self.txtData.captioning = ""
        //self.txtData.translation = ""
        //self.translator?.cancel()
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
            try audioSession.setMode(AVAudioSession.Mode.default)
        } catch{
            print("AVAudioSession error")
        }
        //self.audioRunning = false
    } //引用元 https://www.servernote.net/article.cgi?id=swiftui-voice-to-text
    
    
    // マイクボタンがタップされたとき (これで録音ON,OFFを制御)
    func micButtonTapped(){
        if audioEngine.isRunning {
            recognitionRequest?.endAudio()
            audioEngine.stop()
            isPlaying = false
        } else {
            do {
                try startRecording()
                isPlaying = true
            } catch {
                isPlaying = false
            }
        }
    }
    
    // 会話終わりを検出して再起動掛けるためのタイマー
    func TimerStart(_ interval: Double = 1.0, Sentiment: String){
        // TimerPublisherが存在しているときは念の為処理をキャンセル
        if let _timer = timer{
            _timer.cancel()
        }
        
        timer = Timer.publish(every: interval, on: .main, in: .common)
            // 繰り返し処理の実行
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: ({_ in
                
                self.count += 1
                
                //録音が終了していたら録音を開始する
                if(self.isPlaying == false){
                    self.micButtonTapped() //録音開始
                }
                //1.5秒経ったとき
                if(self.count == 15){
                    print("録音停止")
                    self.micButtonTapped() //録音停止
                    /*　ここで録音停止、録音開始が出来なかった理由
                    　　　録音停止を実行時、即時停止される訳ではなく、このTimerの処理が終わってから？停止する仕様になっている。
                    　　　なので、1.5秒経った後は録音停止だけを実施し、録音開始の部分は別で作ることで対応。
                    　　　(このifの前に、0.1秒毎にタイマーを監視し、録音停止していたら録音開始する分岐を追加) */
                    
                    //-1.0等は送りづらいので、-1.0<->+1.0 を 0<->200 に変更
                    var SendNumber = Double(Sentiment)!
                    SendNumber = SendNumber * 100 + 100
                    
                    //BluetoothクラスのwriteStringでテキストを送信
                    let BLESend = Bluetooth()
                    BLESend.writeString(text: String(SendNumber))
                    
                    print(String(SendNumber) + ":をBLEで送信しました")
                    
                }
                
        }))
    }

    // タイマーの停止
    func TimerStop(){
        //print("stop Timer")
        timer?.cancel()
        timer = nil
    }
    
    // 翻訳
    func translate(text: String){
        self.translator.translate(text) { (translatedText, error) in
            guard error == nil, let translatedText = translatedText else { return }
            self.translation = translatedText
            
            //self.txtData.translation = translatedText
            //self.txtData.translationChange(str: translatedText)
            //ClosedCapTxt().translation = translatedText
        }
    }
        
    func getPermission(){
        // 非同期で認可要求を行う。
        SFSpeechRecognizer.requestAuthorization { authStatus in

            // UIを更新できるように、アプリのメインスレッドに迂回させる。
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.micEnabled = true
                    
                case .denied, .restricted, .notDetermined:
                    self.micEnabled = false
                    
                default:
                    self.micEnabled = false
                }
            }
        }
    }
}




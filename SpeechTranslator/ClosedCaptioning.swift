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

/*
struct TxtData{
    public var captioning: String = "なにか話しかけてください"
    public var translation: String = "-"
    
    mutating func captioningChange(str: String){
        captioning = str
        print("TxtData-Struct:captioning書き換え：" + captioning)
    }
    
    mutating func translationChange(str: String){
        translation = str
        print("TxtData-Struct:translation書き換え：" + translation)
    }
    
} // 参照：https://chusotsu-program.com/swift-struct-mutating/
 */

/*
class ClosedCapTxt: ObservableObject {
    @Published var captioning: String = "なにか話しかけてください"
    @Published var translation: String = "-"
    
    func captioningChange(str: String){
        captioning = str
        print("TxtData-Struct:captioning書き換え：" + captioning)
    }
    
    func translationChange(str: String){
        translation = str
        print("TxtData-Struct:translation書き換え：" + translation)
    }
    
}
 */


class ClosedCaptioning: ObservableObject {
        
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja_JP"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    //@State var txtData: TxtData = TxtData()
    
    @Published var captioning: String = "なにか話しかけてください"
    @Published var translation: String = "-"
    @Published var isPlaying: Bool = false
    @Published var micEnabled: Bool = false
        
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
                
                //self.txtData.captioning = result.bestTranscription.formattedString
                //self.txtData.captioningChange(str: result.bestTranscription.formattedString)
                //ClosedCapTxt().captioning = result.bestTranscription.formattedString
                //ClosedCapTxt().captioningChange(str: result.bestTranscription.formattedString)
                
                //print("Captioning: \(self.txtData.captioning)")
                //print("ClosedCap-Class:Captioning: \(TxtData().captioning)")
                //print("ClosedCap-Class:Captioning: \(ClosedCapTxt().captioning)")
                
                self.translator.translate(result.bestTranscription.formattedString) { (translatedText, error) in
                    guard error == nil,
                        let translatedText = translatedText
                        else { return }
                    
                    self.translation = translatedText
                    print("ClosedCap-Class:translation: \(self.translation)")
                    
                    //self.txtData.translation = translatedText
                    //self.txtData.translationChange(str: translatedText)
                    //print("ClosedCap-Class:translation: \(self.txtData.translation)")
                    //ClosedCapTxt().translation = translatedText
                    //ClosedCapTxt().translationChange(str: translatedText)
                    //print("ClosedCap-Class:translation: \(ClosedCapTxt().translation)")
                    
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
    
    
    // マイクボタンがタップされたとき
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
    
    /*
    // 絶対起動させる
    func AudioStart(){
        if audioEngine.isRunning {
            print("ここ走る？")
            //処理しない
        } else {
            do {
                try startRecording()
                isPlaying = true
            } catch {
                isPlaying = false
            }
        }
    }
     */
    
    
    func translate(text: String){
        self.translator.translate(text) { (translatedText, error) in
            guard error == nil, let translatedText = translatedText else { return }
            self.translation = translatedText
            
            //self.txtData.translation = translatedText
            //self.txtData.translationChange(str: translatedText)
            //ClosedCapTxt().translation = translatedText
        }
    }
    
    /*
    //テキストのみクリアできないかトライ ぶっちゃけむずそう。
    func txtClear(){
        print("Old:" + self.translation)
        self.captioning = ""
        self.translation = ""
    }
     */
    
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




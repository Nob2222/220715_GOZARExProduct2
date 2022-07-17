//
//  AppDelegate.swift
//  SpeechTranslator
//
//  Created by Daniel Bolella on 10/9/19.
//  Copyright © 2019 Daniel Bolella. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // アプリケーション起動後のカスタマイズのためのオーバーライドポイント。
        FirebaseApp.configure()
        return true
    }
    
    //追加 2022/07/15
    func applicationWillTerminate(_ application: UIApplication) {
        // アプリケーションが終了しようとするときに呼び出される。必要であればデータを保存する。
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // 新しいシーンセッションが作成されるときに呼び出されます。
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // ユーザーがシーンセッションを破棄するときに呼び出されます。
        // アプリケーションが実行されていない間にセッションが破棄された場合、これは application:didFinishLaunchingWithOptions のすぐ後に呼び出されます。
        // 破棄されたシーンに固有のリソースは戻らないので、このメソッドを使用して解放してください。
    }


}


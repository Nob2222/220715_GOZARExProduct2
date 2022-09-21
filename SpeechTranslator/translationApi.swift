//
//  translationApi.swift
//  SpeechTranslator
//
//  Created by Hasegawa Akito on 2022/07/18.
//  Copyright © 2022 Daniel Bolella. All rights reserved.
//

import Foundation

class translationApi: ObservableObject {
    struct En_object: Codable {
            var code: Int
            var text: String
        }
    
    func translation(text_ja: String) {
        
        guard let url = URL(string: "https://script.google.com/macros/s/AKfycbwDp3NLE0GV7JZInJ0UV7dF9ISFMPBc3j2ACxKBwqsEpcWwyb6bSc7BZY3j-TXq7NRF/exec?text=\(text_ja)&source=ja&target=en") else { return }
                URLSession.shared.dataTask(with: url) {(data, response, error) in
                    do {
                        if let data = data {
                            let decoded = try JSONDecoder().decode(En_object.self, from: data)
                            print(decoded)
                        } else {
                            print("No data", data as Any)
                        }
                    } catch {
                        print("Error", error)
                    }
                }.resume()
        print(text_ja)
    }
    
    
}

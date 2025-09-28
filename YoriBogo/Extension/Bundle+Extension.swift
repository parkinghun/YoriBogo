//
//  Bundle+Extension.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import Foundation

extension Bundle {
    static func getSecrets(for key: Secrets) -> String {
        guard let filePath = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plistDict = NSDictionary(contentsOfFile: filePath) else {
            fatalError("Couldn't find file 'Info.plist'.")
        }
        
        guard let value = plistDict.object(forKey: key.rawValue) as? String else {
            fatalError("Couldn't find key '\(key.rawValue)' in 'Info.plist'.")
        }
        
        return value
    }
    
    enum Secrets: String {
        case key = "SecretKey"
    }
}

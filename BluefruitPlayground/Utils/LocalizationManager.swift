//
//  LocalizationManager.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 10/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation

class LocalizationManager {
    // Config
    private static let kDefaultLanguageCode = "en"
    private static let kDebugShowDummyCharacters = false

    // Singleton
    static let shared = LocalizationManager()

    // Data
    private var localizationBundle: Bundle?

    var languageCode: String {
        didSet {
          updateBundle()
        }
    }

    // MARK: - Lifecycle
    init() {
        self.languageCode = LocalizationManager.kDefaultLanguageCode
        updateBundle()      // needed because didSet is not invoked from initializer
    }

    // MARK: - Bundle management
    private func updateBundle() {
        localizationBundle = nil

        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj") {
            localizationBundle = Bundle(path: path)
        } else {
            if let range = languageCode.range(of: "-") {

                let baseCode = String(languageCode[..<range.lowerBound])
                if let path =  Bundle.main.path(forResource: baseCode, ofType: "lproj") {
                    localizationBundle = Bundle(path: path)
                }
            }

            if localizationBundle == nil {
                DLog("Error setting languageCode: \(languageCode). Bundle does not exist")
            }
        }
    }

    // MARK: - Localized Strings
    func localizedString(_ key: String) -> String {
        return localizedString(key, description: nil)
    }

    func localizedString(_ key: String, description: String?) -> String {
        var result: String!

        if let string = localizationBundle?.localizedString(forKey: key, value: description, table: nil) {
            result = string
        } else {
            result = key
        }

        if LocalizationManager.kDebugShowDummyCharacters {
            result = String(repeating: "x", count: result.count)
        }

        return result
    }
}

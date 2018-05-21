//
//  Keychain.swift
//  Pushbud
//
//  Created by Daria.R on 4/13/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import Foundation

class Keychain {

    private static let keyPrefix = "\(Bundle.main.bundleIdentifier!).KcStore."
    
    // MARK: - Public
    static func set(_ value: String, forKey key: String) {
        var dictionary = newSearchDictionary(forKey: keyPrefix + key)
        let val = value.data(using: .utf8, allowLossyConversion: false)!

        if valueData(forKey: key) == nil {
            dictionary[kSecValueData as String] = val as AnyObject?
            SecItemAdd(dictionary as CFDictionary, nil)
        } else {
            let updateDictionary: [String: AnyObject] = [kSecValueData as String: val as AnyObject]
            SecItemUpdate(dictionary as CFDictionary, updateDictionary as CFDictionary)
        }
    }

    static func get(_ key: String) -> String? {
        if let valueData = valueData(forKey: key) {
            return String(data: valueData, encoding: .utf8)
        }
        
        return nil
    }

    static func unset(_ key: String) {
        let searchDictionary = newSearchDictionary(forKey: keyPrefix + key)
        SecItemDelete(searchDictionary as CFDictionary)
    }

    // MARK: - Private
    private static func valueData(forKey key: String) -> Data?  {
        
        var searchDictionary = newSearchDictionary(forKey: keyPrefix + key)
        
        searchDictionary[kSecMatchLimit as String] = kSecMatchLimitOne
        searchDictionary[kSecReturnData as String] = kCFBooleanTrue
        
        var retrievedData: AnyObject?
        let status = SecItemCopyMatching(searchDictionary as CFDictionary, &retrievedData)
        
        var data: Data?
        if status == errSecSuccess {
            data = retrievedData as? Data
        }
        
        return data
    }

    private static func newSearchDictionary(forKey key: String) -> [String: AnyObject] {
        let encodedIdentifier = key.data(using: String.Encoding.utf8, allowLossyConversion: false)
        
        var searchDictionary = basicDictionary()
        searchDictionary[kSecAttrGeneric as String] = encodedIdentifier as AnyObject?
        searchDictionary[kSecAttrAccount as String] = encodedIdentifier as AnyObject?
        
        return searchDictionary
    }

    private static func basicDictionary() -> [String: AnyObject] {
        let serviceName = Bundle(for: self).infoDictionary![kCFBundleIdentifierKey as String] as! String
        return [kSecClass as String : kSecClassGenericPassword, kSecAttrService as String : serviceName as AnyObject]
    }
}

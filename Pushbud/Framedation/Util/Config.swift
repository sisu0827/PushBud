//
//  Config.swift
//  PushBud
//
//  Created by Tomasz Chodakowski-Malkiewicz on 16/05/16.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import Foundation

class Config {
    
    typealias OSHandleNotificationReceivedBlock = ()->Void
    
    static let apiGmtFormatter = DateFormatter()
    static let IsDevelopmentMode = true
    static let main: [String: String] = NSDictionary.fromPlist(named: "Config").toPairs
    static var userProfile: User?

    let isChatEnable: Bool
    
    var locale: String {
        didSet {
            APIClient.Headers["X-Client-Locale"] = locale
            APIClient.Headers["Accept-Language"] = locale.leftSubstring(length: 2)
        }
    }
    
    var device: Device? {
        didSet {
            if let deviceId = self.device?.id {
                let device = self.device!
                Keychain.set(deviceId + device.apnToken, forKey: "keyDeviceAuth")
            }
        }
    }
    
    private var preferredLocale: String {
        if let language = Locale.current.languageCode {
            return language
        }
        
        if let language = Locale.preferredLanguages.first {
            return language
        }
        
        return "nb-NO"
    }

    private var askedForPushAuthorization = false
    
    static let shared = Config()
    
    private init() {
        if let values = Keychain.get("keyDeviceAuth")?.components(separatedBy: "$#||#$"), values.count == 3 {
            self.device = Device(id: values[0], apnToken: values[1])
        }
        
        self.locale = Locale.preferredLanguages.first ?? "nb-NO"
        
        URLSessionConfiguration.default.timeoutIntervalForResource = 120.0

        // Setup Chat Options
        let options = EMOptions(appkey: "1100170531002317#pushbud")
        options?.apnsCertName = nil
        if let error = EMClient.shared().initializeSDK(with: options) {
            self.isChatEnable = false
            DLog(error, level: .error)
            // TODO: - Record this error
        } else {
            self.isChatEnable = true
        }
    }
    
}

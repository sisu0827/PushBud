//
//  Constants.swift
//  PushBud
//
//  Created by Tomasz Chodakowski-Malkiewicz on 14/05/16.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import UIKit

struct Constants {
    static let screenScale = UIScreen.main.scale
    static let screenSize = UIScreen.main.bounds.size
    static let localDateFormatShort = "yyyy-MM-dd'T'HH:mm:ss"
    static let mapKey = "AIzaSyBuIYzAT24IT2MlHj-bmfRCs3c78W2hfog"
}

struct ErrorConstants {
    static let decodeErrorDomain = "no.mequire.jsondecode"
//    static let innerErrorKey = "innerError"
}

struct StorageConstants {
    
    static let isRequestedUpgradeToAlwaysUseLocation = "requestedUpgradeToAlwaysUseLocation"
    static let keyHidePopularTagsDialog = "hidePopularTagsDialog"
    static let keyLastUserLocation = "lastUserLocation"
    
    static let firstLoginSucceededKey = "firstLoginSucceeded"
    static let username = "keyUsername"
    static let userEmail = "keyUserEmail"
    static let displayName = "keyUserDisplayName"
    static let profilePicture = "profilePicture"
    
    static var authKeys: [String] {
        return [username, userEmail, displayName, profilePicture]
    }
}

struct CommonStr {
    
    struct TrackingTerm {
        static let expired = LocStr("Tracking.Expiry.End")
        static let seconds = LocStr("Tracking.Expiry.Second")
        static let minute = LocStr("Tracking.Expiry.Minute")
        static let hours = LocStr("Tracking.Expiry.Hours")
        static let day = LocStr("Tracking.Expiry.Day")
        static let dayHours = LocStr("Tracking.Expiry.DayHours")
    }
    
}


struct NotificationNames {
    
    static let tryAuthorizePush = "tryAuthorizePush"
    
}

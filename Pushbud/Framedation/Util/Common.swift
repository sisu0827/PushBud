//
//  Common.swift
//  Pushbud
//
//  Created by Daria.R on 4/14/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import Foundation

struct DateTerm {
    static let justNow = LocStr("Date.JustNow")
    static let minutesAgo = LocStr("Date.MinutesAgo")
    static let hourAgo = LocStr("Date.HourAgo")
    static let hoursAgo = LocStr("Date.HoursAgo")
    static let yesterdayAt = LocStr("Date.YesterdayAt")
    static let thisYearAt = LocStr("Date.ThisYearAt")
    static let pastYearAt = LocStr("Date.PastYearAt")
}

struct FeedTerm {
    static let numberOfLikes = LocStr("Feed.NumberOfLikes")
    static let numberOfComments = LocStr("Feed.NumberOfComments")
}

// MARK: - Common Methods
func LocStr(_ key: String) -> String {
    let result = NSLocalizedString(key, comment: "")
    
    if (result == key && Config.IsDevelopmentMode && key.range(of: ".") != nil) {
        return "💬\(key)💬"
    }
    
    return result
}

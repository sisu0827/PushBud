//
//  String.swift
//  PushBud
//
//  Created by R.Daria on 06/06/16.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import UIKit

extension String {
    
    var escaped: String? {
        var set = CharacterSet()
        set.formUnion(CharacterSet.urlQueryAllowed)
        set.remove(charactersIn: "[].:/?&=;+!@#$()',*\"") // remove the HTTP ones from the set.
        return self.addingPercentEncoding(withAllowedCharacters: set)
    }
    
    func trim(_ emptyToNil: Bool = true)->String? {
        let text = self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if (!emptyToNil) {
            return text
        }
        
        return text.isEmpty ? nil : text
    }
    
    func leftSubstring(length: Int) -> String {
        if (self.characters.count > length) {
            return self.substring(to: self.index(startIndex, offsetBy: length))
        }
        
        return length > 0 ? self : ""
    }

    func nsRange(fromRange range: Range<Index>) -> NSRange {
        let length = self.characters.distance(from: range.lowerBound, to: range.upperBound)
        return NSRange(location: self.characters.distance(from: self.startIndex, to: range.lowerBound), length: length)
    }

//    func lastIndex(of target: String) -> Int? {
//        if let range = self.range(of: target, options: .backwards) {
//            return characters.distance(from: startIndex, to: range.lowerBound)
//        } else {
//            return nil
//        }
//    }
//    
//    var lastWord: String? {
//        guard let start = self.lastIndex(of: " "), start >= 0 else { return nil }
//
//        let startIndex = self.index(self.startIndex, offsetBy: start + 1)
//        
//        return self[startIndex..<self.endIndex].trim()
//    }
    
}

extension Int {

    // MARK: - Converts degrees to radians
    
    var toRadians: CGFloat {
        return CGFloat(self) / 180.0 * CGFloat.pi
    }
    
}

extension Date {
    var toReadable: String {
        let calendar = NSCalendar.current

        if calendar.isDateInToday(self) {
            let timeInt = self.timeIntervalSinceNow
            if timeInt > -2 {
                return DateTerm.justNow
            } else if timeInt > -60 {
                return String(format: DateTerm.minutesAgo, 0)
            } else if timeInt > -3600 {
                return String(format: DateTerm.minutesAgo, abs(Int(timeInt / 60)))
            } else {
                let hours = Int(timeInt / 60 / 60)
                if (hours < -1) {
                    return String(format: DateTerm.hoursAgo, abs(hours))
                } else {
                    return DateTerm.hourAgo
                }
            }
        }
        
        let formatter = DateFormatter()
        if calendar.isDateInYesterday(self) {
            formatter.dateFormat = DateTerm.yesterdayAt
        } else if calendar.isDate(self, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = DateTerm.thisYearAt
        } else {
            formatter.dateFormat = DateTerm.pastYearAt
        }
        
        return formatter.string(from: self)
    }
}

extension Data {
    
    func jsonObject(_ options: JSONSerialization.ReadingOptions = .allowFragments) -> Any? {
        do {
            return try JSONSerialization.jsonObject(with: self, options: options)
        } catch { }
        return nil
    }
    
    var apiError: String? {
        if let dict = self.jsonObject() as? [String: Any], let apiError: String = dict["error"] as? String, apiError.hasPrefix("APIError.") {
            return apiError
        }

        return nil
    }
    
    func jsonDict(_ options: JSONSerialization.ReadingOptions = .allowFragments) -> NSDictionary {
        do {
            if let data = try JSONSerialization.jsonObject(with: self, options: options) as? NSDictionary {
                return data
            }
        } catch { }
        return Dictionary<String, AnyObject>() as NSDictionary
    }
    
    var toImage: UIImage? {
        return UIImage(data: self)
    }
}

extension NSDictionary {
    
    func getValue<T:Comparable>(_ ofKey: String) -> T? {
        return self[ofKey] as? T
    }
    
    static func fromPlist(named: String) -> NSDictionary {
        let pathForResource = Bundle.main.path(forResource: named, ofType: "plist")!
        return NSDictionary(contentsOfFile: pathForResource)!
    }
    
    var toPairs: [String : String] {
        var result = [String : String]()

        self.forEach { (key, value) in
            if let key = key as? String, let value = value as? String {
                result[key] = value
            }
        }

        return result
    }
    
}

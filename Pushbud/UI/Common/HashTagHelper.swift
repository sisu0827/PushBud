//
//  HashTagHelper.swift
//  Pushbud
//
//  Created by Daria.R on 18/06/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit
import Smile

class HashTagHelper {
    
    private let regex = try! NSRegularExpression(pattern: "#[^[:punct:][:space:]]+") // #\\S+
    
    /*func find(inText text: String, byTagIdsFrom tags: [FeedTag]?, removeHashChar: Bool = false) -> [(id: Int?, text: String, range: NSRange?)]? {
        let nsText = text as NSString
        var results: [(Int?, String, NSRange?)] = []
        let matches = self.regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        for match in matches {
            var hashTag = nsText.substring(with: match.range)
            if (removeHashChar) {
                hashTag.remove(at: hashTag.startIndex)
            }
            guard let tagName = Smile.removeEmojis(string: hashTag).trim() else { continue }
            
            if (tags == nil) {
                results.append((nil, tagName, nil))
            } else if let index = tags!.index(where: { $0.name == tagName }) {
                results.append((tags![index].id, tagName, match.range))
            } else {
                print("here")
            }
        }
        
        return results.isEmpty ? nil : results
    }*/
    
    func find(in text: String) -> [String]? {
        let nsText = text as NSString
        var results = [String]()
        self.matches(text: text, nsText: nsText).forEach {
            var text = nsText.substring(with: $0.range)
            text.remove(at: text.startIndex)
            if let text = Smile.removeEmojis(string: text).trim() {
                results.append(text)
            }
        }
        
        return results.isEmpty ? nil : results
    }
    
    func find(in tags: [Tag], toText text: String, attributes: [String : Any]?) -> NSAttributedString? {
        let result = NSMutableAttributedString(string: text, attributes: attributes)
        var count = 0
        let utf16 = text.utf16
        let endIndex = text.endIndex
        for tag in tags.sorted(by: { $0.name.characters.count > $1.name.characters.count }) {
            
            var startIndex = text.startIndex
            
            while let range = text.range(of: "#" + tag.name, options: [.literal, .caseInsensitive], range: startIndex..<endIndex) {

                let from = range.lowerBound.samePosition(in: utf16)
                let start = utf16.distance(from: utf16.startIndex, to: from)
                let length = utf16.distance(from: from, to: range.upperBound.samePosition(in: utf16))
                
                result.addAttribute(NSLinkAttributeName, value: "\(tag.id):", range: NSMakeRange(start, length))
                startIndex = range.upperBound
                count += 1
            }
        }
        
        return count > 0 ? result : nil
    }
    
    private func matches(text: String, nsText: NSString) -> [NSTextCheckingResult] {
        return self.regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
    }

}

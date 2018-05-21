//
//  Comment.swift
//  PushBud
//
//  Created by Daria.R on 31/07/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import Foundation
import ObjectMapper

struct FeedComment {
    let id: Int
    let text: String
    let date: Date
    let user: User
}

extension FeedComment: ImmutableMappable {
    
    init(map: Map) throws {
        id = try map.value("id")
        text = try map.value("text")
        
        /* let _likes: Int? = try? map.value("likes")
        likes = _likes ?? 0
        
        let _isLike: Bool? = try? map.value("is_liked")
        isLike = _isLike ?? false */

        let userId: Int? = try? map.value("user_id")
        
        self.user = User(
            id: userId ?? 0, //try map.value("user_id"),
            name: nil,
            username: try map.value("username"),
            email: nil,
            picture: try? map.value("profile_picture")
        )
        
        var parsedDate: Date?
        if let date: String = try? map.value("inserted_at") {
            parsedDate = Config.apiGmtFormatter.date(from: date)
        }
        self.date = parsedDate ?? Date()
    }
    
}

extension FeedComment {
    
    var attributedText: NSAttributedString {
        let username = self.user.username
        let attrStr = NSMutableAttributedString(string: username + " " + self.text)
        attrStr.addAttributes([
            NSFontAttributeName: Theme.Font.medium.withSize(14),
            NSForegroundColorAttributeName: UIColor.black,
        ], range: NSRange(location: 0, length: username.characters.count))

        return attrStr
    }
    
}

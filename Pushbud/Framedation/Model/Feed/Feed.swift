//
//  Feed.swift
//  PushBud
//
//  Created by Daria.R on 4/13/17.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import Foundation
import ObjectMapper

struct Feed {
    let id: Int
    let text: String
    let latitude: Double
    let longitude: Double
    let pictureUrl: String
    let date: Date
    let place: String?
    let address: String?
    
    var user: UserExtended
    var likes: Int
    var comments: Int
    var isLike: Bool
    var isReport: Bool
    var isOwner: Bool
    var tags: [Tag]?
}

extension Feed: ImmutableMappable {
    
    init(map: Map) throws {
        id = try map.value("id")
        text = try map.value("slug")
        latitude = try map.value("lat")
        longitude = try map.value("lng")
        user = try map.value("user")
        isLike = try map.value("is_liked")
        
        var i: Int?

        i = try? map.value("comments")
        comments = i ?? 0
        
        i = try? map.value("likes")
        likes = i ?? 0
        
        pictureUrl = try map.value("picture_url")
        tags = try? map.value("tags")
        
        let _isReport: Bool? = try? map.value("is_reported")
        isReport = _isReport ?? false
        
        place = try? map.value("place")
        address = try? map.value("address")
        
        isOwner = try map.value("is_owner")
        
        var localDate: Date?
        if let value: String = try? map.value("inserted_at") {
            localDate = Config.apiGmtFormatter.date(from: value)
        }
        
        date = localDate ?? Date()
    }
    
}

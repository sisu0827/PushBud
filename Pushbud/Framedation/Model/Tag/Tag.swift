//
//  Tag.swift
//  Pushbud
//
//  Created by Daria.R on 4/13/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import Foundation
import ObjectMapper

struct Tag {
    let id: Int
    let name: String
    var count: Int
    var isFollowed: Bool
}

extension Tag: ImmutableMappable {
    
    init(map: Map) throws {
        id = try map.value("id")
        name = try map.value("name")
        
        let _count: Int? = try? map.value("followers_count")
        count = _count ?? 0
        
        let _followed: Bool? = try? map.value("is_following")
        isFollowed = _followed ?? false
    }
    
}

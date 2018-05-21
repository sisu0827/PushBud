//
//  Notify.swift
//  Pushbud
//
//  Created by Daria.R on 19/06/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import Foundation
import ObjectMapper

struct Notify {
    let id: Int
    let text: String
    let date: Date
//    var isNew: Bool
}

extension Notify: ImmutableMappable {
    
    init(map: Map) throws {
        self.id = try map.value("id")
        self.text = try map.value("text")
//        self.isNew = try map.value("is_new")
        self.date = Config.apiGmtFormatter.date(from: try map.value("inserted_at")) ?? Date()
    }
    
}

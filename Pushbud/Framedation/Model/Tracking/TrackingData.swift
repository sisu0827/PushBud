//
//  TrackingData.swift
//  Pushbud
//
//  Created by Audun Froysaa on 13.01.2018.
//  Copyright © 2018 meQuire AS. All rights reserved.
//

import Foundation
import ObjectMapper

struct TrackingData {
    let user: User
    let position : Position
}

extension TrackingData: ImmutableMappable {
    
    init(map: Map) throws {
        self.user = try map.value("user")
        self.position = try map.value("position")
    }
    
}

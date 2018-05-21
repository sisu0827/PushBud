//
//  Tracking.swift
//  Pushbud
//
//  Created by Daria.R on 12/9/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import Foundation
import ObjectMapper

struct Tracking {
    let id: Int
    let user: User
    let isRequest: Bool
    var isAccepted: Bool
}

extension Tracking: ImmutableMappable {
    
    init(map: Map) throws {
        id = try map.value("id")
        
        let _user: User = try map.value("tracking")
        isRequest = _user.username == Config.userProfile?.username
        self.user = isRequest ? try map.value("tracker") : _user
        
//        isAccepted = (arc4random_uniform(UInt32(2)) as NSNumber).boolValue
        isAccepted = try map.value("is_accepted")
    }
    
}

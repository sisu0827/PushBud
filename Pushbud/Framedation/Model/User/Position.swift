//
//  Position.swift
//  Pushbud
//
//  Created by Audun Froysaa on 13.01.2018.
//  Copyright © 2018 meQuire AS. All rights reserved.
//
import Foundation
import ObjectMapper

struct Position {
    let lat: NSNumber
    let lng : NSNumber
}

extension Position: ImmutableMappable {
    
    init(map: Map) throws {
        self.lat = try map.value("lat")
        self.lng = try map.value("lng")
        
    }
    
}


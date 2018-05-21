//
//  User.swift
//  Pushbud
//
//  Created by Daria.R on 4/13/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import Foundation
import ObjectMapper

struct User {
    let id: Int
    let name: String?
    let username: String
    let email: String?
    let picture: String?
}

extension User: ImmutableMappable {
    
    init(map: Map) throws {
        id = try map.value("user_id")
        name = try? map.value("name")
        username = try map.value("username")
        email = try? map.value("email")
        picture = try? map.value("profile_picture")
    }
    
}

struct UserExtended {
    let id: Int
    let name: String
    let picture: String?
    var isFriend: Bool
    var isMuted: Bool
    var radius: Float?
    
    // Friendship
    var friendshipId: Int?
    var isInvitor: Bool
    var isInvitation: Bool
}

extension UserExtended: ImmutableMappable {
    
    init(map: Map) throws {
        self.id = try map.value("user_id")
        
        let displayName: String? = try? map.value("name")
        if (displayName?.isEmpty ?? true) {
            self.name = try map.value("username")
        } else {
            self.name = displayName!
        }
        
        self.picture = try? map.value("profile_picture")
        
        let isFriend: Bool? = try? map.value("is_friends")
        self.isFriend = isFriend ?? false
        
        let friendship: [String : Any] = try map.value("friendship")
        self.friendshipId = friendship["friendship_id"] as? Int
        self.isInvitor = (friendship["is_invitor"] as? Bool) ?? false
        self.isInvitation = (friendship["is_invitation"] as? Bool) ?? false
        
        let isMuted: Bool? = try? map.value("is_muted")
        self.isMuted = isMuted ?? false
        self.radius = try? map.value("radius")
    }
    
}

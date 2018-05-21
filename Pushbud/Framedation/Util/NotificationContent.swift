//
//  Common.swift
//  Pushbud
//
//  Created by Daria.R on 4/14/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import Foundation
import UserNotifications

enum NotificationCategory: String {
    case friendRequest = "FriendRequest"
    case friendRequestAccepted = "FriendRequestAccepted"
}

@available(iOS 10.0, *)
class NotificationContent: UNMutableNotificationContent {
    
    let notificationCategory: NotificationCategory?
    
    init(title: String?, body: String?, category: String?, locArgs: [String]?) {
        if category != nil {
            self.notificationCategory = NotificationCategory(rawValue: category!)
        } else {
            self.notificationCategory = nil
        }
        
        super.init()
        
        self.title = LocStr(title ?? "Notification.DefaultTitle")
        
        if (body != nil) {
            let localized = LocStr(body!)
            if let arg = locArgs?.first {
                self.body = String(format: localized, arg)
            } else {
                self.body = localized
            }
        }

        if (self.notificationCategory != nil) {
            self.categoryIdentifier = category!
        }
        
        self.sound = UNNotificationSound.default()
    }
    
    convenience init(userInfo: [AnyHashable : Any], aps: [String : Any]) {
        let alert = aps["alert"] as? [String : Any]
        let args: [String]? = alert?["loc-args"] as? [String]
        self.init(title: alert?["title-loc-key"] as? String, body: alert?["loc-key"] as? String, category: aps["category"] as? String, locArgs: args)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

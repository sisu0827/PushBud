//
//  Message.swift
//  PushBud
//
//  Created by Audun Froysaa on 14.08.2016.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import Foundation
import LNRSimpleNotifications
import AudioToolbox

public enum UserMessageStyle {
    case message
    case warning
    case error
    case other
}

class UserMessage {

    static let shared = UserMessage()
    private let manager = LNRNotificationManager()
    private var notificationStyle = UserMessageStyle.other {
        didSet {
            switch notificationStyle {
            case .message:
                manager.notificationsBackgroundColor = UIColor.white
                manager.notificationsTitleTextColor = UIColor.black
                manager.notificationsBodyTextColor = UIColor.darkGray
                manager.notificationsIcon = UIImage(named: "happySmall")
            case .warning:
                manager.notificationsBackgroundColor = UIColor.yellow
                manager.notificationsTitleTextColor = UIColor.black
                manager.notificationsBodyTextColor = UIColor.darkGray
                manager.notificationsIcon = UIImage(named: "sadSmall")
            case .error:
                manager.notificationsBackgroundColor = UIColor.red
                manager.notificationsTitleTextColor = UIColor.white
                manager.notificationsBodyTextColor = UIColor.white
                manager.notificationsIcon = UIImage(named: "sadSmall")
            case .other: break;
            }
        }
    }
    
    init() {
        manager.notificationsPosition = LNRNotificationPosition.top

        if let soundURL = Bundle.main.url(forResource: "ClickSoundEffect", withExtension: "wav") {
            var mySound: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &mySound)
            manager.notificationSound = mySound
        }
        
    }

    func show(_ title: String, body: String? = nil, style: UserMessageStyle = .error) {
        guard manager.activeNotification == nil else {
            _ = manager.dismissActiveNotification(completion: { (_) in
                UserMessage.shared.show(title, body: body, style: style)
            })
            return
        }

        if (self.notificationStyle != style) {
            self.notificationStyle = style
        }
        
        manager.showNotification(notification: LNRNotification(title: title, body: body, duration: 5) { [weak self] in
            _ = self?.manager.dismissActiveNotification(completion: nil)
        })
    }

}


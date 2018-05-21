//
//  MapBadgeButton.swift
//  Pushbud
//
//  Created by Daria.R on 12/9/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

enum MapBadgeButtonType: Int {
    case tracking = 1, friend
}

class MapBadgeButton: UIButton {

    var text: String? {
        set {
            self.badge.text = newValue
            
            let animation = CABasicAnimation()
            animation.keyPath = "transform.scale"
            animation.fromValue = 1.5
            animation.toValue = 1
            animation.duration = 0.2
            animation.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 1.3, 1.0, 1.0)
            
            self.badge.layer.add(animation, forKey: "bounceAnimation")
            
            let badgeFrame = CGRect(x: 0, y: 0, width: self.badgeSize, height: self.badgeSize)
            UIView.animate(withDuration: animation.duration, animations: { [weak self] in
                if let badge = self?.badge {
                    badge.alpha = 0.9
                    badge.frame = badgeFrame
                }
            }) { [weak self] _ in
                self?.badge.layer.removeAllAnimations()
            }
        }
        get {
            return self.badge.text
        }
    }
    
    private var badge = UILabel()
    private let badgeSize: CGFloat

    required init(_ frame: CGRect, type: MapBadgeButtonType, badgeSize: CGFloat = 18.0) {
        self.badgeSize = badgeSize
        
        super.init(frame: frame)
        
        badge.alpha = 0
        badge.backgroundColor = Theme.destructiveBackgroundColor
        badge.clipsToBounds = true
        badge.font = UIFont.systemFont(ofSize: 13)
        badge.layer.cornerRadius = badgeSize / 2
        badge.textAlignment = .center
        badge.textColor = .white
        self.addSubview(badge)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

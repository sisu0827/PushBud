//
//  ButtonEx.swift
//  Pushbud
//
//  Created by Daria.R on 26/04/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

extension UIButton {
    
    func addPulseAnimation() {
        self.layer.removeAllAnimations()

        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.duration = 0.6
        pulse.fromValue = 1.0
        pulse.toValue = 1.12
        pulse.autoreverses = true
        pulse.repeatCount = 1
        pulse.initialVelocity = 0.5
        pulse.damping = 0.8
        
        let animationGroup = CAAnimationGroup()
        animationGroup.duration = 2.7
        animationGroup.repeatCount = 1
        animationGroup.animations = [pulse]
        
        self.layer.add(pulse, forKey: "pulse")
    }
    
    func imageOnRight(_ imageSize: CGSize, spacing: CGFloat, width: CGFloat) {
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing - imageSize.width, bottom: 0, right: 0)
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: width - spacing - imageSize.width, bottom: 0, right: 0)
    }
    
    func updateToggleFriend(_ isFriend: Bool) {
        if (isFriend) {
            self.setTitle(LocStr("User.Following"), for: .normal)
            self.backgroundColor = .white
            self.setTitleColor(.lightGray, for: .normal)
            self.layer.borderWidth = 0.5
        } else {
            self.setTitle(LocStr("User.Follow"), for: .normal)
            self.backgroundColor = UIColor(red: 0.0, green: 0.329412, blue: 0.65098, alpha: 1.0) //0054A6
            self.setTitleColor(.white, for: .normal)
            self.layer.borderWidth = 0.0
        }
    }
}

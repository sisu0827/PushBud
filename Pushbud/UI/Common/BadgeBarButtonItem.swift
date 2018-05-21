//
//  BadgeBarButtonItem.swift
//  Pushbud
//
//  Created by Daria.R on 19/06/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class BadgeBarButtonItem: UIBarButtonItem {

    let badgeLabel = UILabel()
    var badgeValue: Int? {
        didSet {
            if badgeValue == nil || (badgeValue == 0 && shouldHideBadgeAtZero) {
                self.removeBadge()
                return
            }
            
            if (badgeLabel.superview == nil) {
                customView!.addSubview(badgeLabel)
                self.updateBadgeFrame()
            }

            updateBadgeValue(animated: true)
        }
    }
    
    var shouldHideBadgeAtZero: Bool = true

    init(customView: UIView) {
        super.init()
        
        badgeLabel.textColor = UIColor.white
        badgeLabel.font = Theme.Font.medium.withSize(12)
        badgeLabel.backgroundColor = UIColor.red
        badgeLabel.textAlignment = .center
        badgeLabel.clipsToBounds = true
        
        self.customView = customView
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func removeBadge() {
        guard self.badgeLabel.superview != nil else { return }

        UIView.animate(withDuration: 0.2, animations: {
            self.badgeLabel.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        }, completion: { finished in
            self.badgeLabel.removeFromSuperview()
            self.badgeLabel.transform = .identity
        })
    }
    
    private func badgeExpectedSize() -> CGFloat {
        let frameLabel = self.duplicateLabel(badgeLabel)
        frameLabel.sizeToFit()
        return max(4, max(frameLabel.frame.size.width, frameLabel.frame.size.height))
    }
    
    private func duplicateLabel(_ labelToCopy: UILabel) -> UILabel {
        let dupLabel = UILabel(frame: labelToCopy.frame)
        dupLabel.text = labelToCopy.text
        
        return dupLabel
    }

    private func updateBadgeValue(animated: Bool) {
        let count = String(self.badgeValue!)
        
        if (animated && badgeLabel.text != count) {
            let animation: CABasicAnimation = CABasicAnimation()
            animation.keyPath = "transform.scale"
            animation.fromValue = 1.5
            animation.toValue = 1
            animation.duration = 0.2
            animation.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 1.3, 1.0, 1.0)
            badgeLabel.layer.add(animation, forKey: "bounceAnimation")
        }

        badgeLabel.text = count
        
        UIView.animate(withDuration: animated ? 0.2 : 0) {
            self.updateBadgeFrame()
        }
    }

    private func updateBadgeFrame() {
        let size = self.badgeExpectedSize()
        let half = size / 2
        
        self.badgeLabel.frame = CGRect(x: half, y: -min(9, half), width: size, height: size)
        self.badgeLabel.layer.cornerRadius = half
    }
}

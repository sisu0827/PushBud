//
//  MapToggleTrackingButton.swift
//  Pushbud
//
//  Created by Daria.R on 5/16/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class MapToggleTrackingButton: UIButton {
    
    var arrow: CAShapeLayer?
    var navTip = CAShapeLayer()
    
    override func layoutSubviews() {
        guard self.arrow == nil else { return }

        let arrow = CAShapeLayer()
        let size = self.frame.width
        arrow.strokeColor = self.tintColor.cgColor
        arrow.lineWidth = 1.5
        arrow.fillColor = UIColor.clear.cgColor
        
        let halfSize = size / 2
        
        arrow.path = arrowPath(halfSize)
        arrow.bounds = CGRect(x: 0, y: 0, width: halfSize, height: halfSize)
        arrow.position = CGPoint(x: halfSize, y: halfSize)
        arrow.shouldRasterize = true
        arrow.rasterizationScale = UIScreen.main.scale
        arrow.drawsAsynchronously = true
        arrow.setAffineTransform(CGAffineTransform.identity.rotated(by: 0.66))
        
        self.arrow = arrow
        self.layer.addSublayer(self.arrow!)
        
        //
        let navTipPath = UIBezierPath()
        navTipPath.move(to: CGPoint(x: halfSize * 0.5, y: halfSize * 0.5))
        navTipPath.addLine(to: CGPoint(x: halfSize * 0.5, y: halfSize))
        
        self.navTip.strokeColor = self.tintColor.cgColor
        self.navTip.lineWidth = 1.5
        self.navTip.path = navTipPath.cgPath
        self.navTip.bounds = CGRect(x: 0, y: 0, width: halfSize, height: size * 0.9)
        self.navTip.position = CGPoint(x: halfSize, y: size)
    }
    
    private func arrowPath(_ max: CGFloat) -> CGPath {
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: max * 0.5, y: 0))
        bezierPath.addLine(to: CGPoint(x: max * 0.1, y: max))
        bezierPath.addLine(to: CGPoint(x: max * 0.5, y: max * 0.65))
        bezierPath.addLine(to: CGPoint(x: max * 0.9, y: max))
        bezierPath.addLine(to: CGPoint(x: max * 0.5, y: 0))
        bezierPath.close()
        
        return bezierPath.cgPath
    }

    func showFollowingIndicator() {
        self.layer.addSublayer(navTip)
    }
    
    func hideFollowingIndicator() {
        self.navTip.removeFromSuperlayer()
    }
    
}

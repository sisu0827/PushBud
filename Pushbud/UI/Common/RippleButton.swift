//
//  RippleButton.swift
//  Pushbud
//
//  Created by Daria.R on 22/11/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class RippleButton: UIButton {
    
    // MARK: - Views
    let view = UIView()
    let bgView = UIView()
    
    // MARK: - Properties
    var rippleColor: UIColor {
        set {
            self.view.backgroundColor = newValue
        }
        get  {
            return self.view.backgroundColor ?? UIColor.clear
        }
    }
    
    var rippleBgColor: UIColor?
    var ripplePercent: CGFloat = 1.1
    var shadowRippleRadius: Float = 1
    var shadowRippleEnable: Bool = true
    var touchUpAnimationTime: Double = 0.45
    
    private var tempShadowRadius: CGFloat = 0
    private var tempShadowOpacity: Float = 0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    // MARK: Overrides
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setupRippleView()
        self.bgView.layer.frame = bounds
        if let imageView = self.imageView {
            self.bringSubview(toFront: imageView)
        }
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        UIView.animate(withDuration: 0.1, delay: 0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
            self.bgView.alpha = 1
        }, completion: nil)
        
        self.view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        
        UIView.animate(withDuration: 0.7, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
            self.view.transform = CGAffineTransform.identity
        }, completion: nil)
        
        if shadowRippleEnable {
            tempShadowRadius = layer.shadowRadius
            tempShadowOpacity = layer.shadowOpacity
            
            let shadowAnim = CABasicAnimation(keyPath:"shadowRadius")
            shadowAnim.toValue = shadowRippleRadius
            
            let opacityAnim = CABasicAnimation(keyPath:"shadowOpacity")
            opacityAnim.toValue = 1
            
            let groupAnim = CAAnimationGroup()
            groupAnim.duration = 0.7
            groupAnim.fillMode = kCAFillModeForwards
            groupAnim.isRemovedOnCompletion = false
            groupAnim.animations = [shadowAnim, opacityAnim]
            
            layer.add(groupAnim, forKey:"shadow")
        }
        
        return super.beginTracking(touch, with: event)
    }
    
    override func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        self.animateToNormal()
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        self.animateToNormal()
    }
    
    // MARK: - Private
    private func animateToNormal() {
        UIView.animate(withDuration: 0.1, delay: 0, options: .allowUserInteraction, animations: {
            self.bgView.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: self.touchUpAnimationTime, delay: 0, options: .allowUserInteraction, animations: {
                self.bgView.alpha = 0
            }, completion: nil)
        })
        
        let shadowAnim = CABasicAnimation(keyPath:"shadowRadius")
        shadowAnim.toValue = self.tempShadowRadius
        
        let opacityAnim = CABasicAnimation(keyPath:"shadowOpacity")
        opacityAnim.toValue = self.tempShadowOpacity
        
        let groupAnim = CAAnimationGroup()
        groupAnim.duration = 0.7
        groupAnim.fillMode = kCAFillModeForwards
        groupAnim.isRemovedOnCompletion = false
        groupAnim.animations = [shadowAnim, opacityAnim]
        
        UIView.animate(withDuration: 0.7, delay: 0, options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction], animations: {
            self.view.transform = .identity
            self.layer.add(groupAnim, forKey:"shadowBack")
        }, completion: nil)
    }
    
    private func setupUI() {
        self.rippleColor = UIColor(white: 1.0, alpha: 0.3)
        self.bgView.alpha = 0
        self.bgView.backgroundColor = self.rippleBgColor ?? self.backgroundColor
        self.bgView.layer.addSublayer(self.view.layer)
        self.layer.addSublayer(bgView.layer)
        
        self.layer.shadowRadius = 0
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowColor = UIColor(white: 0.0, alpha: 0.5).cgColor
    }
    
    private func setupRippleView() {
        let size = bounds.width * ripplePercent
        let halfSize = size / 2
        let x: CGFloat = (bounds.width / 2) - halfSize
        let y: CGFloat = (bounds.height / 2) - halfSize
        
        self.view.frame = CGRect(x: x, y: y, width: size, height: size)
        self.view.layer.cornerRadius = halfSize
    }
    
}

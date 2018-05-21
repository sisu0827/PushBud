//
//  CameraTransition.swift
//  Martoff
//
//  Created by Daria.R on 21/12/16.
//  Copyright © 2017 Martoff. All rights reserved.
//

import UIKit

protocol CircleTransitionType {
    var circleView: UIView { get }
}

class CircleTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    fileprivate let fromView: UIView?
    fileprivate let isPresented: Bool
    fileprivate var context: UIViewControllerContextTransitioning?
    
    init(_ isPresenting: Bool, fromView: UIView? = nil) {
        self.fromView = fromView
        self.isPresented = isPresenting
        
        super.init()
    }
    
    // MARK: - Transitioning delegate
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) else { return }

        let containerView = transitionContext.containerView
        containerView.addSubview(toVC.view)

        var circleView: UIView!
        if (self.fromView == nil) {
            if toVC is CircleTransitionType {
                circleView = (toVC as! CircleTransitionType).circleView
            } else if let navVC = toVC as? UINavigationController {
                circleView = (navVC.topViewController as! CircleTransitionType).circleView
            }
        } else {
            circleView = self.fromView!
        }

        let startCycle = UIBezierPath(ovalIn: circleView.frame)
        let xMax = max(circleView.frame.origin.x, containerView.frame.size.width - circleView.frame.origin.x)
        let yMax = max(circleView.frame.origin.y, containerView.frame.size.height - circleView.frame.origin.y)
        let endCycle = UIBezierPath(arcCenter: containerView.center, radius: sqrt(xMax * xMax + yMax * yMax), startAngle: 0, endAngle: CGFloat.pi * 2.0, clockwise: true)
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = isPresented ? endCycle.cgPath : startCycle.cgPath
        if (isPresented) {
            toVC.view.layer.mask = maskLayer
        } else {
            transitionContext.view(forKey: .from)?.layer.mask = maskLayer
        }
        
        let maskAnim = CABasicAnimation(keyPath: "path")
        maskAnim.fromValue = isPresented ? startCycle.cgPath : endCycle.cgPath
        maskAnim.toValue = isPresented ? endCycle.cgPath : startCycle.cgPath
        maskAnim.duration = transitionDuration(using: transitionContext)
        maskAnim.delegate = self
        maskAnim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        maskLayer.add(maskAnim, forKey: "path")
        
        self.context = transitionContext
    }
    
}

extension CircleTransition: CAAnimationDelegate {
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        context?.completeTransition(flag)
        
        context?.viewController(forKey: .to)?.view.layer.mask = nil
    }
    
}

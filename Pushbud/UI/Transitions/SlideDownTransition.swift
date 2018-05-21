//
//  SlideDownTransition.swift
//  Pushbud
//
//  Created by Daria.R on 27/04/17.
//  Copyright © 2017 Martoff. All rights reserved.
//

import UIKit

class SlideDownTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    var presenting: Bool?
    
    init(presenting: Bool) {
        self.presenting = presenting
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.view(forKey: UITransitionContextViewKey.from)!
        let toVC = transitionContext.view(forKey: UITransitionContextViewKey.to)!
        let containerView = transitionContext.containerView
        
        if presenting == true {
            containerView.addSubview(toVC)
            
            let screenHeight = UIScreen.main.bounds.size.height
            
            toVC.frame.origin.y -= screenHeight
            
            UIView.animate(withDuration: 0.8, delay: 0, options: [], animations: { () -> Void in
                fromVC.transform = CGAffineTransform(translationX: 0, y: screenHeight)
                toVC.transform = CGAffineTransform(translationX: 0, y: screenHeight)
            }) { (completed) -> Void in
                transitionContext.completeTransition(true)
            }
        }
        else {
            toVC.removeFromSuperview()
            fromVC.removeFromSuperview()
            
            containerView.addSubview(fromVC)
            containerView.addSubview(toVC)
            
            UIView.animate(withDuration: 0.8, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
                toVC.transform = CGAffineTransform.identity
                fromVC.transform = CGAffineTransform.identity
            }) { (completed) -> Void in
                transitionContext.completeTransition(true)
            }
        }
    }
}

//
//  BlurTransition.swift
//  Pushbud
//
//  Created by Daria.R on 27/04/17.
//  Copyright © 2017 Martoff. All rights reserved.
//

import UIKit

class BlurTransition: NSObject,UIViewControllerAnimatedTransitioning {
    
    private let isShow: Bool
    private let imageView: UIView
    private let blurEffect = UIBlurEffectStyle.dark
    
    init(isShow: Bool, image: UIImage) {
        self.isShow = isShow
        self.imageView = UIImageView(image: image)
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to) else { return }
        
        defer {
            transitionContext.containerView.addSubview(toView)
        }
        
        guard (self.isShow) else {
            toView.alpha = 0
            let hideView = transitionContext.viewController(forKey: .from)!.view!
            UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0, options: .curveLinear, animations: {
                hideView.alpha = 0.0
                toView.alpha = 1.0
            }, completion: { finished in
                transitionContext.completeTransition(true)
            })
            return
        }

        let containerView = transitionContext.containerView
        let blurView = UIVisualEffectView(frame: containerView.bounds)

        imageView.frame = toView.bounds
        imageView.alpha = 0.0
        toView.insertSubview(blurView, at: 0)
        toView.insertSubview(imageView, at: 0)

        
        let blurEffect = UIBlurEffect(style: self.blurEffect)
//        let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect))
//        vibrancyView.alpha = 0.0
//        vibrancyView.frame = containerView.bounds
//        blurView.contentView.addSubview(vibrancyView)
        
        if #available(iOS 10, *) {
            blurView.effect = nil
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: self.transitionDuration(using: transitionContext), delay: 0, options: UIViewAnimationOptions.curveLinear, animations: {
                self.imageView.alpha = 1
//                vibrancyView.alpha = 0.2
                blurView.effect = blurEffect
            }, completion: { finished in
                transitionContext.completeTransition(true)
            })
        } else {
            blurView.effect = blurEffect
            UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0, options: .curveLinear, animations: {
                self.imageView.alpha = 1
//                vibrancyView.alpha = 0.2
            }, completion: { finished in
                transitionContext.completeTransition(true)
            })
        }
    }
    
}

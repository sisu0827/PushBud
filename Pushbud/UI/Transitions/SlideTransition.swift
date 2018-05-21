//
//  SlideTransition.swift
//  Pushbud
//
//  Created by Daria.R on 27/04/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

enum SlideTransitionDirection {
    case left
    case right
}

class SlideTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    private let direction: SlideTransitionDirection
    private let duration: TimeInterval = 0.33

    init(direction: SlideTransitionDirection) {
        self.direction = direction
        
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to), let fromView = transitionContext.view(forKey: .from) else {
            preconditionFailure("Something is messy")
        }
        
        let container = transitionContext.containerView
        container.addSubview(toView)
        
        guard let toSnap = toView.snapshotView(afterScreenUpdates: true),let fromSnap = fromView.snapshotView(afterScreenUpdates: true) else { return }
        
        fromSnap.frame = fromView.frame
        toSnap.frame = toView.frame
        
        container.addSubview(toSnap)
        container.addSubview(fromSnap)
        
        toView.removeFromSuperview()
        fromView.removeFromSuperview()
        
        toSnap.transform = offscreenTransform(for: toSnap, inContainer: container, isReversed: true)
        
        UIView.animate(withDuration: self.duration, animations: {
            toSnap.transform = .identity
            fromSnap.transform = self.offscreenTransform(for: fromSnap, inContainer: container, isReversed: false)
        }) { finish in
            let transitionCompleted = finish && !transitionContext.transitionWasCancelled
            let endingView = transitionCompleted ? toView : fromView
            container.addSubview(endingView)
            toSnap.removeFromSuperview()
            fromSnap.removeFromSuperview()
            transitionContext.completeTransition(transitionCompleted)
        }
    }
    
    private func offscreenTransform(for view:UIView, inContainer container:UIView, isReversed:Bool) -> CGAffineTransform {
        var transform = view.transform
        switch(self.direction, isReversed) {
        case (.left, false),(.right,true):
            transform = transform.translatedBy(x: -container.bounds.width, y: 0)
        case(.right, false),(.left, true):
            transform = transform.translatedBy(x: container.bounds.width, y: 0)
        }
        transform = transform.scaledBy(x: 0.9, y: 0.9)
        return transform
    }

}

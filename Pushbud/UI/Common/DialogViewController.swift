//
//  DialogViewController.swift
//  Pushbud
//
//  Created by Daria.R on 24/04/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class DialogViewController: UIViewController {
    
    let contentView = UIView()
    private let hideStorageKey: String
    
    private let lblTitle = UILabel()
    private var widthConstraint: NSLayoutConstraint!
    
    required init(_ title: String, hideStorageKey: String? = nil) {
        self.lblTitle.text = title
        self.hideStorageKey = hideStorageKey ?? ""
        self.contentView.translatesAutoresizingMaskIntoConstraints = false

        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.view.alpha = 0
        self.view.backgroundColor = UIColor(white: 0, alpha: 0.7)
        
        self.contentView.backgroundColor = UIColor.white
        self.contentView.layer.cornerRadius = 2
        self.contentView.layer.masksToBounds = true
        self.view.addSubview(self.contentView)
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[p]-(<=1)-[c]", options: .alignAllCenterX, metrics: nil, views: ["p":view, "c":self.contentView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[p]-(<=1)-[c]", options: .alignAllCenterY, metrics: nil, views: ["p":view, "c":self.contentView]))
        self.widthConstraint = NSLayoutConstraint(item: self.contentView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: min(self.view.frame.width - 48, 416))
        self.view.addConstraint(self.widthConstraint)

        //
        self.lblTitle.font = Theme.Font.medium.withSize(16)
        self.lblTitle.numberOfLines = 0
        self.lblTitle.textAlignment = .center
        self.lblTitle.textColor = Theme.Dark.textColor
        self.lblTitle.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.lblTitle)
        Helper.addConstraints(["H:|-12-[lbl]-12-|", "V:|-12-[lbl]"], source: self.contentView, views: ["lbl": self.lblTitle])
        
        //
        if let detailView = self.contentView.subviews.first {
            self.contentView.addConstraint(NSLayoutConstraint(item: detailView, attribute: .top, relatedBy: .equal, toItem: self.lblTitle, attribute: .bottom, multiplier: 1.0, constant: 12))
            Helper.addConstraints(["H:|-12-[dv]-12-|", "V:[dv]-12-|"], source: contentView, views: ["dv": detailView])
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.widthConstraint.constant = min(size.width - 48, 416)
    }
    
    func closeAction() {
        self.dismiss(animated: true, completion: nil)
    }

    func hideFiveMinuteAction() {
        self.hide(byInteval: 300)
    }

    func hideOneDayAction() {
        self.hide(byInteval: 86400)
    }
    
    func hideOneWeekAction() {
        self.hide(byInteval: 604800)
    }
    
    func addDetailViewFromNib<T:UIView>(_ nibNamed: String) -> T? {
        guard let detailView: T = self.contentView.addSubviewFromNib(nibNamed) else { return nil }

        detailView.translatesAutoresizingMaskIntoConstraints = false
        
        return detailView
    }
    
    private func hide(byInteval interval: TimeInterval) {
        UserStorage.shared.store(object: Date().addingTimeInterval(interval), forKey: self.hideStorageKey)
        self.closeAction()
    }
}

extension DialogViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DialogViewControllerTransition()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DialogViewControllerTransition()
    }
    
}

class DialogViewControllerTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let duration = self.transitionDuration(using: transitionContext)
        
        if let dialogVC = transitionContext.viewController(forKey: .to) as? DialogViewController {
            let containerView = transitionContext.containerView
            dialogVC.view.alpha = 0.0
            dialogVC.view.frame = containerView.frame
            dialogVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            dialogVC.view.translatesAutoresizingMaskIntoConstraints = true
            containerView.addSubview(dialogVC.view)
            
            dialogVC.contentView.transform = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height / 2.8)
            
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 1.0, options: [.curveEaseOut], animations: {
                dialogVC.view.alpha = 1
                dialogVC.contentView.transform = CGAffineTransform.identity
            }) { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else if let dialogVC = transitionContext.viewController(forKey: .from) as? DialogViewController {
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
                dialogVC.contentView.transform = CGAffineTransform(translationX: 0, y: -UIScreen.main.bounds.height / 2.8)
                dialogVC.view.alpha = 0
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}

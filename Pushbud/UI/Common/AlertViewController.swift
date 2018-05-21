//
//  AlertViewController.swift
//  Pushbud
//
//  Created by Daria.R on 24/04/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

protocol AlertViewControllerDelegate {
    func alertAction(_ actionCase: Int)
}

struct AlertActionCase {
    let actionCase: Int
    let title: String
}

class AlertViewController: UIViewController {
    
    var delegate: AlertViewControllerDelegate?
    let contentView = UIView()
    
    fileprivate var activeFieldTag: Int?
    fileprivate var keyboardHeight: CGFloat!
    
    private let lblTitle = UILabel()
    private var detailView: UIView?
    private let actions: [AlertActionCase]
    private var widthConstraint: NSLayoutConstraint!
    
    required init(_ title: String, text: String?, actions: [AlertActionCase]? = nil) {
        self.actions = actions ?? [AlertActionCase(actionCase: 0, title: "OK")]
        self.lblTitle.text = title
        if (text != nil) {
            let label = UILabel()
            label.font = Theme.Font.light.withSize(15)
            label.numberOfLines = 0
            label.textColor = Theme.Dark.textColorLighter
            label.text = text
            self.detailView = label
        }
        
        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }
    
    convenience init(_ nib: String, title: String, actions: [AlertActionCase]?) {
        self.init(title, text: nil, actions: actions)
        self.detailView = UINib(nibName: nib, bundle: nil).instantiate(withOwner: self, options: nil).first as? UIView
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
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.contentView)
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[p]-(<=1)-[c]", options: .alignAllCenterX, metrics: nil, views: ["p":view, "c":self.contentView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[p]-(<=1)-[c]", options: .alignAllCenterY, metrics: nil, views: ["p":view, "c":self.contentView]))
        self.widthConstraint = NSLayoutConstraint(item: self.contentView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: min(self.view.frame.width - 48, 416))
        self.view.addConstraint(self.widthConstraint)
        
        self.lblTitle.font = Theme.Font.medium.withSize(16)
        self.lblTitle.numberOfLines = 0
        self.lblTitle.textColor = Theme.Dark.textColor
        self.lblTitle.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.lblTitle)
        Helper.addConstraints(["H:|-24-[lbl]-24-|", "V:|-24-[lbl]"], source: self.contentView, views: ["lbl": self.lblTitle])
        
        if let detailView = self.detailView {
            detailView.translatesAutoresizingMaskIntoConstraints = false
            self.contentView.addSubview(detailView)
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-24-[DV]-24-|", options: [], metrics: nil, views: ["DV": detailView]))
            self.contentView.addConstraint(NSLayoutConstraint(item: detailView, attribute: .top, relatedBy: .equal, toItem: self.lblTitle, attribute: .bottom, multiplier: 1.0, constant: 12))
        }
        
        let bgColor = UIColor(white: 0, alpha: 0.04).toImage
        
        var btnPrev: UIButton!
        for action in self.actions {
            let button = UIButton()
            button.contentEdgeInsets = UIEdgeInsetsMake(10, 20, 10, 20)
            button.setTitle(action.title, for: .normal)
            button.setTitleColor(Theme.Dark.button, for: .normal)
            button.addTarget(self, action: #selector(alertAction(_:)), for: .touchUpInside)
            button.setBackgroundImage(bgColor, for: .highlighted)
            button.tag = action.actionCase
            button.titleLabel!.font = Theme.Font.medium.withSize(16)
            button.translatesAutoresizingMaskIntoConstraints = false
            self.contentView.addSubview(button)
            if (btnPrev == nil) {
                self.contentView.addConstraint(NSLayoutConstraint(item: button, attribute: .top, relatedBy: .equal, toItem: self.detailView ?? self.lblTitle, attribute: .bottom, multiplier: 1.0, constant: 12))
                self.contentView.addConstraint(NSLayoutConstraint(item: button, attribute: .trailing, relatedBy: .equal, toItem: self.contentView, attribute: .trailing, multiplier: 1.0, constant: -8))
                self.contentView.addConstraint(NSLayoutConstraint(item: self.contentView, attribute: .bottom, relatedBy: .equal, toItem: button, attribute: .bottom, multiplier: 1.0, constant: 10))
            } else {
                self.contentView.addConstraint(NSLayoutConstraint(item: button, attribute: .top, relatedBy: .equal, toItem: btnPrev, attribute: .top, multiplier: 1.0, constant: 0))
                self.contentView.addConstraint(NSLayoutConstraint(item: button, attribute: .trailing, relatedBy: .equal, toItem: btnPrev, attribute: .leading, multiplier: 1.0, constant: 0))
            }
            self.contentView.addConstraint(NSLayoutConstraint(item: button, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 90.0))
            btnPrev = button
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.widthConstraint.constant = min(size.width - 48, 416)
    }
    
    // MARK: - Actions
    func alertAction(_ sender: UIButton) {
        var completionBlock: (() -> Void)?
        if (sender.tag > 0) {
            completionBlock = {
                self.delegate?.alertAction(sender.tag)
            }
        }
        dismiss(animated: true, completion: completionBlock)
    }
    
}

extension AlertViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeFieldTag = nil
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeFieldTag = textField.tag
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

extension AlertViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AlertViewControllerTransition()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AlertViewControllerTransition()
    }
    
}

class AlertViewControllerTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let duration = self.transitionDuration(using: transitionContext)
        
        if let alertVC = transitionContext.viewController(forKey: .to) as? AlertViewController {
            let containerView = transitionContext.containerView
            alertVC.view.alpha = 0.0
            alertVC.view.frame = containerView.frame
            alertVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            alertVC.view.translatesAutoresizingMaskIntoConstraints = true
            containerView.addSubview(alertVC.view)
            
            alertVC.contentView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 14.0, options: [.curveEaseIn, .allowUserInteraction, .beginFromCurrentState], animations: {
                alertVC.contentView.transform = CGAffineTransform.identity
                alertVC.view.alpha = 1.0
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        } else if let alertVC = transitionContext.viewController(forKey: .from) as? AlertViewController {
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
                alertVC.contentView.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
                alertVC.view.alpha = 0
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}

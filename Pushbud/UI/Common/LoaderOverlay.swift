//
//  LoaderOverlay.swift
//  Pushbud
//
//  Created by Daria.R on 08/04/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class LoaderOverlay {
    
    private let view: UIView
    private let label = UILabel(frame: CGRect(x: 0, y: 80, width: 0, height: 0))
    var progress: KDCircularProgress?

    private let indicatorTag = 1
    private let tickViewTag = 3

    class var shared: LoaderOverlay {
        struct Static {
            static let instance = LoaderOverlay()
        }
        return Static.instance
    }
    
    // MARK:- Private
    private init() {
        self.view = UIView(frame: CGRect(x: 0, y: 0, width: 110, height: 100))
        self.view.backgroundColor = .black
        self.view.alpha = 0.8
        self.view.layer.cornerRadius = 6
        
        let tickView = TickView(frame: CGRect(x: -5, y: -10, width: 120, height: 120))
        tickView.tag = self.tickViewTag
        tickView.isHidden = true
        self.view.addSubview(tickView)
        
        self.label.textColor = .white
        self.label.textAlignment = .center
        self.label.font = Theme.Font.light.withSize(16)
        self.label.numberOfLines = 0
        self.label.isHidden = true
        self.view.addSubview(label)
        
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        indicator.hidesWhenStopped = true
        indicator.tag = indicatorTag
        self.view.addSubview(indicator)
        indicator.center = CGPoint(x: self.view.frame.width/2.0, y: self.view.frame.height/2.0)
    }
    
    // MARK:- Public
    func showProgress(inView: UIView? = nil) {
        self.progress?.removeFromSuperview()

        let width = self.view.frame.width
        let circularProgress = KDCircularProgress(frame: CGRect(x: 0, y: 0, width: width * 0.75, height: width * 0.75))
        circularProgress.startAngle = -90
        circularProgress.trackColor = Theme.Dark.darker.withAlphaComponent(0.8)
        circularProgress.progressThickness = 0.25
        circularProgress.trackThickness = 0.4
        circularProgress.clockwise = true
        circularProgress.gradientRotateSpeed = 2
        circularProgress.roundedCorners = true
        circularProgress.glowMode = .constant
        circularProgress.glowAmount = 0.5
        circularProgress.set(colors: Theme.Dark.tint)
        self.progress = circularProgress
        self.show(inView: inView)
        self.view.addSubview(circularProgress)
        circularProgress.center = CGPoint(x: width / 2.0, y: self.view.frame.height / 2.0)
    }
    
    func show(inView: UIView? = nil) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        guard let target = inView ?? (UIApplication.shared.delegate?.window)! else { return }
        
        (self.view.viewWithTag(self.indicatorTag) as? UIActivityIndicatorView)?.startAnimating()
        
        if let superview = self.view.superview {
            if (superview == target) {
                return
            }
            self.view.removeFromSuperview()
        }
        
        target.addSubview(self.view)
        self.view.center = target.center
    }
    
    func hideProgress() {
        self.progress?.removeFromSuperview()
        self.progress = nil
        self.hide()
    }
    
    func hide() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        (self.view.viewWithTag(self.indicatorTag) as? UIActivityIndicatorView)?.stopAnimating()

        self.view.removeFromSuperview()
    }
    
    func tick(_ text: String? = nil, center: CGPoint? = nil, inView: UIView? = nil, callback: (() -> ())? = nil) {
        
        (self.view.viewWithTag(self.indicatorTag) as? UIActivityIndicatorView)?.stopAnimating()
        
        guard let target = inView ?? self.view.superview ?? (UIApplication.shared.delegate?.window)!,
              let tickView = self.view.viewWithTag(self.tickViewTag) as? TickView else { return }

        if (self.view.superview == nil) {
            target.addSubview(self.view)
            self.view.center = center ?? target.center
        }
        
        if (text != nil) {
            let width = min(UIScreen.main.bounds.width - 64, 400)
            let height = NSAttributedString(string: text!, attributes: [NSFontAttributeName: self.label.font]).boundingRect(with: CGSize(width: width - 16, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil).height + 16
            
            self.label.frame.size = CGSize(width: width, height: height)
            self.label.isHidden = false
            self.label.text = text
            
            tickView.frame.origin.x = (width / 2) - (tickView.frame.size.width / 2)
            
            self.view.frame.size = CGSize(width: width, height: 100 + height)
            self.view.center = center ?? target.center
        }
        
        tickView.isHidden = false
        tickView.toggle(true)
        
        if (!self.view.isDescendant(of: target)) {
            target.addSubview(self.view)
            self.view.alpha = 0
            UIView.animate(withDuration: 0.2, animations: {
                self.view.alpha = 0.8
            })
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            tickView.toggle(false)
            callback?()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                UIView.animate(withDuration: 0.3 + (text == nil ? 0 : 0.5), animations: {
                    self.view.alpha = 0
                }, completion: { finished in
                        self.hideProgress()
                        self.label.isHidden = true
                        self.view.alpha = 0.8
                        self.view.frame.size = CGSize(width: 110, height: 100)
                        tickView.frame.origin.x = 55 - (tickView.frame.size.width / 2)
                })
            }
        }
    }
}

//
//  ViewEx.swift
//  Pushbud
//
//  Created by Daria.R on 23/04/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

extension UIView {
    
    var toImage: UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0.0)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func addSubviewFromNib<T:UIView>(_ nibNamed: String, iFrame: CGRect? = nil) -> T? {
        let nib = UINib(nibName: nibNamed, bundle: nil)
        let topLevelObjects = nib.instantiate(withOwner: self, options: nil)
        
        let instance = topLevelObjects.filter {$0 is T}.first as? T
        if (iFrame != nil) {
            instance!.frame = iFrame!
        }
        self.addSubview(instance!)
        
        return instance
    }
    
    func addSubviews(_ views: [UIView]) {
        views.forEach { v in
            v.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(v)
        }
    }
    
    func addTarget(target: Any, action: Selector, cancelsTouchesInView: Bool = true) {
        let tapRecognizer = UITapGestureRecognizer(target: target, action: action)
        tapRecognizer.cancelsTouchesInView = cancelsTouchesInView
        self.addGestureRecognizer(tapRecognizer)
    }
    
    func addEmptyView(_ textView: UIView, button: UIButton? = nil, image: UIImage? = nil) -> UIView {
        let emptyView = UIView()
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(textView)
        var formats = ["H:|-0-[lbl]-0-|"]
        
        if (image == nil) {
            formats.append("V:|-0-[lbl]")
        } else {
            let imageView = UIImageView(image: image)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            emptyView.addSubview(imageView)
            emptyView.addConstraints([
                NSLayoutConstraint(item: imageView, attribute: .top, relatedBy: .equal, toItem: emptyView, attribute: .top, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: emptyView, attribute: .centerX, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: textView, attribute: .top, relatedBy: .equal, toItem: imageView, attribute: .bottom, multiplier: 1.0, constant: 16)
                ])
        }
        Helper.addConstraints(formats, source: emptyView, views: ["lbl": textView])
        
        if (button != nil) {
            button!.backgroundColor = Theme.Splash.lightColor
            button!.titleLabel?.font = Theme.Font.light.withSize(16)
            button!.layer.cornerRadius = 3
            button!.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            button!.translatesAutoresizingMaskIntoConstraints = false
            emptyView.addSubview(button!)
            
            emptyView.addConstraints([
                NSLayoutConstraint(item: button!, attribute: .top, relatedBy: .equal, toItem: textView, attribute: .bottom, multiplier: 1.0, constant: 16),
                NSLayoutConstraint(item: button!, attribute: .centerX, relatedBy: .equal, toItem: emptyView, attribute: .centerX, multiplier: 1.0, constant: 0),
                ])
            
        }
        
        let screenSize = UIScreen.main.bounds.size
        let w = min(screenSize.width, screenSize.height) - 32
        
        self.addSubview(emptyView)
        self.addConstraints([
            NSLayoutConstraint(item: emptyView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: w),
            NSLayoutConstraint(item: emptyView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: emptyView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: emptyView, attribute: .bottom, relatedBy: .equal, toItem: button == nil ? textView : button, attribute: .bottom, multiplier: 1.0, constant: 0)])
        
        return emptyView
    }
    
    func pbAddShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 1
    }

    func errorShake() {
        let shake = CABasicAnimation(keyPath: "position")
        shake.duration = 0.05
        shake.repeatCount = 2
        shake.autoreverses = true
        
        let fromPoint = CGPoint(x: self.center.x - 5, y: self.center.y)
        let toPoint = CGPoint(x: self.center.x + 5, y: self.center.y)
        
        shake.fromValue = NSValue(cgPoint: fromPoint)
        shake.toValue = NSValue(cgPoint: toPoint)
        layer.add(shake, forKey: "position")
    }
    
    func addProgress(_ style: UIActivityIndicatorViewStyle = .gray) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: style)
        self.addSubview(indicator)
        
        indicator.center = CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0)
        indicator.startAnimating()
        
        return indicator
    }
    
    func alignBottomWithMargin(_ margin: CGFloat) {
        if (self.superview != nil) {
            var frame = self.frame
            frame.origin.y = self.superview!.frame.height - self.frame.height - margin
            self.frame = frame
        }
    }
    
    func setY(_ y: CGFloat) {
        var frame = self.frame
        frame.origin.y = y
        self.frame = frame
    }

    // Fill the view's width to its superview from it's current x origin
    func fillWidth() {
        if (self.superview != nil) {
            var frame = self.frame
            frame.size.width = self.superview!.frame.width - self.frame.minX
            self.frame = frame
        }
    }
    
    // Fill the view's height to its superview from it's current y origin
    func fillHeight() {
        if (self.superview != nil) {
            var frame = self.frame
            frame.size.height = self.superview!.frame.height - self.frame.minY
            self.frame = frame
        }
    }
    
}

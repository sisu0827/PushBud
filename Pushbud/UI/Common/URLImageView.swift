//
//  URLImageView.swift
//  PushBud
//
//  Created by Tomasz Chodakowski-Malkiewicz on 06/09/16.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import UIKit

class URLImageView : UIImageView {
    
    var indicatorStyle: UIActivityIndicatorViewStyle = .gray
    private var currentURL: String?
    
    func reset() {
        self.currentURL = nil
        self.image = nil
        self.viewWithTag(4)?.removeFromSuperview()
    }
    
    func download(_ uri: String, animated: Bool = true) {
        guard (self.currentURL != uri) else { return }
        
        self.currentURL = uri
        if let image = ImageClient.shared.getCached(uri) {
            self.image = image
            return
        }
        
        self.addIndicator()
        
        ImageClient.shared.download(uri) { [weak self] image, url, loadedFromCache in
            
            guard self?.currentURL == url else { return }
            
            let isAnimated = (animated && !loadedFromCache)
            
            self!.viewWithTag(4)?.removeFromSuperview()
            self!.alpha = isAnimated ? 0 : 1
            self!.image = image
            
            if isAnimated {
                UIView.animate(withDuration: 0.3) { self!.alpha = 1 }
            }
        }
    }
    
    // MARK:- Private
    private func addIndicator() {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: self.indicatorStyle)
        indicator.tag = 4
        indicator.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(indicator)

        let v: [String : Any] =  ["p": self, "c": indicator]
        self.addConstraints(
            NSLayoutConstraint.constraints(withVisualFormat: "V:[p]-(<=1)-[c]", options: .alignAllCenterX, metrics: nil, views: v) +
            NSLayoutConstraint.constraints(withVisualFormat: "H:[p]-(<=1)-[c]", options: .alignAllCenterY, metrics: nil, views: v)
        )

        indicator.startAnimating()
    }

}

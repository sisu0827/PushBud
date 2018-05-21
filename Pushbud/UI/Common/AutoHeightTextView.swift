//
//  AutoHeightTextView.swift
//  PushBud
//
//  Created by Daria.R on 18/06/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class AutoHeightTextView: UITextView {
    
    var heightConstraint: NSLayoutConstraint?
    var heightPadding: CGFloat = 4
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
        self.addConstraint(self.heightConstraint!)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.heightConstraint?.constant = self.fittedWidthContentHeight + self.heightPadding
    }

}

//
//  LabelInset.swift
//  PushBud
//
//  Created by Daria.R on 02/02/16.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import UIKit

class LabelInset: UILabel {
    
    var customInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, self.customInsets))
    }
    
    override var intrinsicContentSize : CGSize {
        var intrinsicSuperViewContentSize = super.intrinsicContentSize
        intrinsicSuperViewContentSize.height += customInsets.top + customInsets.bottom
        intrinsicSuperViewContentSize.width += customInsets.left + customInsets.right
        return intrinsicSuperViewContentSize
    }
}

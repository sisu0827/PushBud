//
//  TextViewEx.swift
//  Pushbud
//
//  Created by Daria.R on 18/06/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

extension UITextView{
    
    var fittedWidthContentHeight: CGFloat {
        return self.sizeThatFits(CGSize(width: self.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
    }
    
}

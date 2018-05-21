//
//  ColorEx.swift
//  Pushbud
//
//  Created by Daria.R on 23/04/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

extension UIColor {
    
    var toImage: UIImage? {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(cgColor)
        context?.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    class func progressColor(value: Double) -> UIColor {
        if value <= 90 {
            return Theme.ProgressColor.red
        } else if value <= 180 {
            return Theme.ProgressColor.orange
        } else if value <= 270 {
            return Theme.ProgressColor.yellow
        }
        return Theme.ProgressColor.green
    }
}

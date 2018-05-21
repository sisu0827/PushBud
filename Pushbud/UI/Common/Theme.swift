//
//  Theme.swift
//  Pushbud
//
//  Created by Daria.R on 08/04/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

struct Theme {
    
    struct ProgressColor {
        static let red = UIColor.init(red: 200.0/255.0, green: 38.0/255.0, blue: 6.0/255.0, alpha: 1.0)
        static let orange = UIColor.init(red: 222.0/255.0, green: 106.0/255.0, blue: 16.0/255.0, alpha: 1.0)
        static let yellow = UIColor.init(red: 211.0/255.0, green: 177.0/255.0, blue: 28.0/255.0, alpha: 1.0)
        static let green = UIColor.init(red: 0/255.0, green: 136.0/255.0, blue: 43.0/255.0, alpha: 1.0)
        static let track = UIColor.init(red: 245.0/255.0, green: 245.0/255.0, blue: 245.0/255.0, alpha: 1.0)
    }

    struct Font {
        static let light: UIFont = UIFont(name: "Avenir-Light", size: 1)!
        static let medium: UIFont = UIFont(name: "Avenir-Medium", size: 1)!
        static let bold: UIFont = UIFont(name: "Avenir-Heavy", size: 1)!
    }
    
    static let keypadButtonColor = UIColor(red: 0.0, green: 0.466667, blue: 1.0, alpha: 1.0) // 0077ff
    static let badgeBackgroundColor = UIColor(red: 0.929412, green: 0.576471, blue: 0.188235, alpha: 1.0) // ED9330
    static let destructiveBackgroundColor = UIColor(red: 0.92549, green: 0.211765, blue: 0.188235, alpha: 1.0) // EC3630
    static let destructiveTextColor = UIColor(red: 0.960784, green: 0.239216, blue: 0.239216, alpha: 1.0) // F53D3D
    
    struct Light {
        static let background = UIColor(red: 0.972549, green: 0.972549, blue: 0.972549, alpha: 1.0) // F8F8F8
        static let separator = UIColor(red: 0.866667, green: 0.866667, blue: 0.866667, alpha: 1.0).cgColor // DDDDDD
        static let textButton = UIColor(red: 0.0, green: 0.4, blue: 0.6, alpha: 1.0) // 006699
        static let textButtonDarker = UIColor(red: 0.0, green: 0.286275, blue: 1.0, alpha: 1.0) //0049FF
    }

    struct Dark {
        static let background = UIColor(red: 0.203922, green: 0.203922, blue: 0.203922, alpha: 1.0) // 343434
        static let button = UIColor(red: 0.305882, green: 0.458824, blue: 0.972549, alpha: 1.0) //4E75F8
        static let textColor = UIColor(red: 0.137255, green: 0.137255, blue: 0.137255, alpha: 1.0) // rgb(35,35,35)
        static let textColorLighter = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1) // 999999
        static let separator = UIColor(red: 0.568627, green: 0.568627, blue: 0.568627, alpha: 1.0) // 919191
        static let tint = UIColor(red: 0.854902, green: 0.854902, blue: 0.854902, alpha: 1.0) // DADADA
        static let darker = UIColor(red: 0.152941, green: 0.152941, blue: 0.152941, alpha: 1.0) // 272727
        static let badge = UIColor(red: 0.94, green: 0.28, blue: 0.21, alpha: 1.0) // EF4836
    }
    
    struct Splash {
        static let darkColor = UIColor(red: 0.0196078, green: 0.137255, blue: 0.266667, alpha: 1.0) // 052344
        static let lightColor = UIColor(red:0.16, green:0.50, blue:0.73, alpha:1.0)
        //UIColor(red: 0.0862745, green: 0.631373, blue: 0.521569, alpha: 1.0) // 16a185
        static let lighterColor = UIColor(red:0.20, green:0.60, blue:0.86, alpha:1.0)
        //UIColor(red: 0.121569, green: 0.368627, blue: 0.447059, alpha: 1.0) // 1f5e72
    }

    static func setUpAppearance() {
        let ap = UINavigationBar.appearance()
        ap.barTintColor = Theme.Splash.darkColor
        ap.tintColor = UIColor.white

        let imgBack = UIImage(named: "back")
        ap.backIndicatorImage = imgBack
        ap.backIndicatorTransitionMaskImage = imgBack
        
        let textField = UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        textField.backgroundColor = Theme.Dark.tint
        textField.tintColor = Theme.Dark.darker
        
        ap.titleTextAttributes = [NSFontAttributeName: Theme.Font.medium.withSize(15), NSForegroundColorAttributeName: ap.tintColor]
        UIBarButtonItem.appearance().setTitleTextAttributes(ap.titleTextAttributes, for: .normal)

        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([
            NSFontAttributeName: Theme.Font.light.withSize(15),
            NSForegroundColorAttributeName: Theme.Light.textButton
        ], for: .normal)
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [CommonNavigationController.self]).setTitleTextAttributes([
            NSFontAttributeName: Theme.Font.light.withSize(15),
            NSForegroundColorAttributeName: UIColor.white
        ], for: .normal)
    }
    
}

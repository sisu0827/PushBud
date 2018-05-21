//
//  SideBar.swift
//  PushBud
//
//  Created by Daria.R on 24/04/17.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import UIKit

class Sidebar: UIView {
    
    let barWidth: CGFloat = 265

    var isOpen = false

    override init (frame : CGRect) {
        super.init(frame : frame)

        // Alpha Background
        self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        self.layer.opacity = 0

        let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(Sidebar.toggle))
        swipeRecognizer.direction = .left
        self.addGestureRecognizer(swipeRecognizer)
        
        self.addTarget(target: self, action: #selector(Sidebar.tapRecognized(_:)), cancelsTouchesInView: false)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }

    func tapRecognized(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: sender.view)
        if let _ = sender.view?.hitTest(location, with: nil) as? Sidebar {
            self.toggle()
        }
    }
    
    func toggle(_ show: Bool = false) {
        let sidebarView = self.subviews.first as? SidebarView
        if (show) {
            self.isHidden = false
            sidebarView?.reloadProfile()
        } else {
            sidebarView?.imgUser.animStop()
        }
        
        self.isOpen = show
        
        UIView.animate(withDuration: 0.4, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
            self.subviews[0].frame.origin.x = show ? 0 : -self.barWidth
            self.layer.opacity = show ? 1 : 0
        }) { (Bool) in
            if (!show) {
                self.isHidden = true
            }
        }
    }
}

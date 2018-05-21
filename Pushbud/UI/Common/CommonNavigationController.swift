//
//  CommonNavigationController.swift
//  Pushbud
//
//  Created by Daria.R on 24/04/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class CommonNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
}

extension CommonNavigationController: UINavigationControllerDelegate, BaseNavigationController {
    
    func showNotifs() {
        self.pushViewController(NotifyViewController(), animated: true)
    }
    
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if !(viewController is NotifyViewController) {
            self.addNotifsButton(viewController.navigationItem, selector: #selector(showNotifs))
        }
    }

}

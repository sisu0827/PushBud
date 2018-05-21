//
//  BaseNavigationController.swift
//  Pushbud
//
//  Created by Daria.R on 19/06/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

protocol BaseNavigationController {
    func showNotifs()
}

extension BaseNavigationController {
    
    func addNotifsButton(_ navigationItem: UINavigationItem, selector: Selector?, force: Bool = false) {
        var badgeButton: BadgeBarButtonItem?
        
        if let index = navigationItem.rightBarButtonItems?.index(where: { $0 is BadgeBarButtonItem }) {
            badgeButton = navigationItem.rightBarButtonItems![index] as? BadgeBarButtonItem
        } else if (selector != nil) {
            
            let image = UIImage(named: "tb_bell\(arc4random_uniform(4))")!.withRenderingMode(.alwaysTemplate)
            let button = UIButton()
            button.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
            button.setBackgroundImage(image, for: .normal)
            button.addTarget(self, action: selector!, for: .touchUpInside)
            badgeButton = BadgeBarButtonItem(customView: button)
            navigationItem.rightBarButtonItem = badgeButton
        }
        
        guard (force || NotifyManager.count == nil) else {
            badgeButton?.badgeValue = NotifyManager.count
            return
        }
        
        HTTP.New(APIClient.baseURL + "notifications/count", type: .GET, headers: APIClient.Headers).start { response in
            
            let statusCode = response.statusCode
            
            #if DEBUG
                print("NotificationsCount-HTTP\(statusCode ?? 0)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            #endif

            guard statusCode == 200, let json = response.data.jsonObject() as? [String : Int] else { return }
            
            NotifyManager.count = json["other_count"]
            badgeButton?.badgeValue = NotifyManager.count
            
            if let mapVC = (UIApplication.shared.delegate as! AppDelegate).mapViewController {
                mapVC.updateBadge(json["tracking_requests"] ?? 0, type: .tracking)
                mapVC.updateBadge(json["friends_request"] ?? 0, type: .friend)
            }
        }
        
    }
    
}

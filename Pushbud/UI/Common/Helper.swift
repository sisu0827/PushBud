//
//  Helper.swift
//  Pushbud
//
//  Created by Daria.R on 08/04/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

struct Permission {
    
    static var isPushGranted: Bool {
        guard let settings = UIApplication.shared.currentUserNotificationSettings else {
            return false
        }
        
        return !settings.types.isEmpty
    }
    
}

class Helper {
    
    static func openLocationSettings() {
        if #available(iOS 10.0, *) {
            openSettings(url: "App-Prefs:root=Privacy&path=LOCATION")
        } else {
            openSettings(url: "prefs:root=LOCATION_SERVICES")
        }
    }
    
    static func openSettings(url: String) {
        guard let settingsUrl = URL(string: url), UIApplication.shared.canOpenURL(settingsUrl) else { return }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(settingsUrl)
        } else {
            UIApplication.shared.openURL(settingsUrl)
        }
    }
    
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    static func notifyApiError(_ error: NSError?) {
        if (error?.isNetworkError == true) {
            UserMessage.shared.show(LocStr("Error.NoNetworkTitle"), body: LocStr("Error.NoNetworkTip"))
        } else {
            UserMessage.shared.show(LocStr("Failure"), body: LocStr("Error.Unexpected"))
        }
    }
    
    static func alertNoNetRetry(_ target: AlertViewControllerDelegate, retryCase: Int, cancelCase: Int? = nil) {
        guard let presentedViewController = target as? UIViewController else { return }
        
        var actions = [AlertActionCase(actionCase: retryCase, title: LocStr("Retry"))]
        if let cancelCase = cancelCase {
            actions.append(AlertActionCase(actionCase: cancelCase, title: LocStr("Cancel")))
        }
        let viewController = AlertViewController(LocStr("Error.NoNetworkTitle"), text: LocStr("Error.NoNetworkTip"), actions: actions)
        viewController.delegate = target
        presentedViewController.present(viewController, animated: true)
    }
    
    static func freeFile(_ url: URL, fileExtension: String) -> URL {
        let fileMgr = FileManager.default
        var rnd: URL
        
        repeat {
            rnd = url.appendingPathComponent(NSUUID().uuidString + fileExtension)
        } while (fileMgr.fileExists(atPath: rnd.path))
        
        return rnd
    }
    
    @discardableResult
    static func addProgress(in view: UIView, style: UIActivityIndicatorViewStyle = .gray, containerSize: CGSize? = nil) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: style)
        view.addSubview(indicator)
        
        let size = containerSize ?? view.frame.size
        indicator.center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
        indicator.startAnimating()
        
        return indicator
    }
    
    static func addConstraints(_ formats: [String], source: UIView, views: [String : Any], options: NSLayoutFormatOptions = []) {
        var constraints = [NSLayoutConstraint]()
        formats.forEach {
            constraints += NSLayoutConstraint.constraints(withVisualFormat: $0, options: options, metrics: nil, views: views)
        }
        source.addConstraints(constraints)
    }

//    static func getTextSize(text: String, font: UIFont, maxSize: CGSize? = nil) -> CGSize {
//        let attributed = NSAttributedString(string: text, attributes: [NSFontAttributeName: font])
//        return attributed.boundingRect(with: maxSize ?? CGSize(width: 320, height: 24), options: .usesLineFragmentOrigin, context: nil).size
//    }
    
    static func newOrientation(new: UIDeviceOrientation, old: UIDeviceOrientation) -> UIDeviceOrientation? {
        switch (new) {
        case .portrait, .portraitUpsideDown, .landscapeLeft, .landscapeRight:
            if (new != old) {
                return new
            }
        default: break;
        }
        
        return nil
    }
    
    static func getTextSize(_ text: String, font: UIFont) -> CGSize {
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: font]).size()
    }
    
}

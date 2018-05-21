//
//  CameraViewController.swift
//  Martoff
//
//  Created by Daria.R on 21/12/16.
//  Copyright © 2017 Martoff. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

class PermissionView: UIView {
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.backgroundColor = UIColor.white
        
        //
        let button = UIButton()
        button.setTitle(LocStr("Gallery.Permission.Button").uppercased(), for: .normal)
        button.backgroundColor = UIColor(red: 0.156863, green: 0.666667, blue: 0.92549, alpha: 1.0) //28aaec
        button.titleLabel?.font = Theme.Font.medium.withSize(16)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.lightGray, for: .highlighted)
        button.layer.cornerRadius = 3
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        button.addTarget(self, action: #selector(settingAction), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(button)
        Helper.addConstraints(["H:[sv]-(<=1)-[btn]"], source: self, views: ["sv":self, "btn":button], options: .alignAllCenterY)
        Helper.addConstraints(["V:[sv]-(<=1)-[btn]"], source: self, views: ["sv":self, "btn":button], options: .alignAllCenterX)
        self.addConstraint(NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 44))
        
        //
        let label = UILabel()
        label.textColor = UIColor(red: 102/255, green: 118/255, blue: 138/255, alpha: 1)
        label.font = Theme.Font.light.withSize(14)
        label.text = LocStr("Gallery.MediaPermission.Info")
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(label)
        
        var labelConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-50-[lbl]-50-|", options: [], metrics: nil, views: ["lbl": label])
        labelConstraints.append(NSLayoutConstraint(item: label, attribute: .bottom, relatedBy: .equal, toItem: button, attribute: .top, multiplier: 1.0, constant: -33))
        labelConstraints.append(NSLayoutConstraint(item: label, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20))
        self.addConstraints(labelConstraints)
        
        //
        let imageView = UIImageView(image: UIImage(named: "gallery_permission_view_camera"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(imageView)
        
        var imageConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:[sv]-(<=1)-[img]", options: .alignAllCenterY, metrics: nil, views: ["sv":self, "img":imageView])
        imageConstraints.append(NSLayoutConstraint(item: imageView, attribute: .bottom, relatedBy: .equal, toItem: label, attribute: .top, multiplier: 1.0, constant: -12))
    }
    
    // MARK: - Action
    func settingAction() {
        if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.openURL(settingsURL)
        }
    }
}

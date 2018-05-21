//
//  TrackingTableViewCell.swift
//  PushBud
//
//  Created by Daria.R on 12/9/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class TrackingTableViewCell : UITableViewCell {
    
    @IBOutlet var imgUser: AvatarImageView!
    @IBOutlet var lblUser: UILabel!
    @IBOutlet var lblStatus: LabelInset!
    @IBOutlet var btnMenu: UIButton!

    var userTapRecognizer: UIGestureRecognizer?
    var btnDecline: UIButton?
    var btnAccept: UIButton?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.isUserInteractionEnabled = true
        
        self.lblStatus.customInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        self.lblStatus.font = Theme.Font.light.withSize(11)
        self.lblStatus.layer.backgroundColor = Theme.Light.separator
        self.lblStatus.layer.cornerRadius = 3
        
        self.btnMenu.setImage(UIImage(named: "dropdown")?.withRenderingMode(.alwaysOriginal), for: .normal)
        self.btnMenu.setTitle(nil, for: .normal)
        self.btnMenu.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.4).cgColor
        self.btnMenu.layer.cornerRadius = 2
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        self.imgUser.reset()
        
        if let userView = self.lblUser.superview {
            userView.gestureRecognizers?.forEach {
                userView.removeGestureRecognizer($0)
            }
        }
        
        if (self.lblStatus.tag == 1) {
            self.lblStatus.layer.backgroundColor = Theme.Light.separator
            self.lblStatus.tag = 0
            self.lblStatus.textColor = .black
        }
        
        if let recognizer = self.userTapRecognizer {
            self.lblUser.superview?.removeGestureRecognizer(recognizer)
            self.userTapRecognizer = nil
        }

        self.btnMenu.removeTarget(nil, action: nil, for: .allEvents)

        guard (self.btnDecline != nil) else { return }

        self.btnDecline!.removeFromSuperview()
        self.btnDecline = nil

        self.btnAccept?.removeFromSuperview()
        self.btnAccept = nil
    }

    func setupUiForInvitaion(target: Any, index: Int) {
        self.btnMenu.isHidden = true
        
        self.btnAccept = UIButton()
        self.btnAccept!.setImage(UIImage(named: "accept"), for: .normal)
        self.btnAccept!.addTarget(target, action: #selector(TrackingTableViewController.acceptAction(_:)), for: .touchUpInside)
        
        self.btnDecline = UIButton()
        self.btnDecline!.tintColor = .red
        self.btnDecline!.setImage(UIImage(named: "decline")?.withRenderingMode(.alwaysTemplate), for: .normal)
        self.btnDecline!.addTarget(target, action: #selector(TrackingTableViewController.declineAction(_:)), for: .touchUpInside)
        
        for btn in [btnAccept!, btnDecline!] {
            btn.tag = index
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.layer.cornerRadius = 19
            btn.layer.borderWidth = 1.5
            btn.layer.borderColor = Theme.Dark.tint.cgColor
            self.contentView.addSubview(btn)
        }
        
        self.contentView.addConstraints([
            NSLayoutConstraint(item: self.btnAccept!, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.btnDecline!, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.btnDecline!, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: self.btnAccept!, attribute: .trailing, relatedBy: .equal, toItem: btnDecline, attribute: .leading, multiplier: 1.0, constant: -16)])
    }
}

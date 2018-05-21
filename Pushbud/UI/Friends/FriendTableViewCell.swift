//
//  FriendTableViewCell.swift
//  PushBud
//
//  Created by Daria.R on 25/04/17.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import UIKit

class FriendTableViewCell : UITableViewCell {
    
    @IBOutlet var imgUser: AvatarImageView!
    @IBOutlet var lblUser: UILabel!
    @IBOutlet var btnUser: UIButton!

    private var btnUserLeftInset: CGFloat!
    
    var btnDecline: UIButton?
    var btnAccept: UIButton?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.isUserInteractionEnabled = true
        
        self.btnUser.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.4).cgColor
        self.btnUser.layer.cornerRadius = 2
        self.btnUserLeftInset = self.btnUser.contentEdgeInsets.left
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        self.imgUser.reset()
        
        if let userView = self.lblUser.superview {
            userView.gestureRecognizers?.forEach {
                userView.removeGestureRecognizer($0)
            }
        }
        
        self.btnUser.isHidden = false
        self.btnUser.contentEdgeInsets.left = self.btnUserLeftInset
        self.btnUser.setImage(nil, for: .normal)

        guard (self.btnDecline != nil) else { return }

        self.btnDecline!.removeFromSuperview()
        self.btnDecline = nil

        self.btnAccept?.removeFromSuperview()
        self.btnAccept = nil
    }

    func setupUiForInvitaion(target: Any, index: Int) {
        self.btnUser.isHidden = true
        
        self.btnAccept = UIButton()
        self.btnAccept!.setImage(UIImage(named: "accept"), for: .normal)
        self.btnAccept!.addTarget(target, action: #selector(FriendsTableViewController.acceptInvitationAction(_:)), for: .touchUpInside)
        
        self.btnDecline = UIButton()
        self.btnDecline!.tintColor = .red
        self.btnDecline!.setImage(UIImage(named: "decline")?.withRenderingMode(.alwaysTemplate), for: .normal)
        self.btnDecline!.addTarget(target, action: #selector(FriendsTableViewController.declineInvitationAction(_:)), for: .touchUpInside)
        
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

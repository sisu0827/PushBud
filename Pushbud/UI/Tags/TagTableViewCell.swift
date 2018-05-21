//
//  TagTableViewCell.swift
//  PushBud
//
//  Created by Daria.R on 25/04/17.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import UIKit

class TagTableViewCell : UITableViewCell {
    
    let lblTag = UILabel()
    let btnAction = RippleButton()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.setupUI()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        
        self.setupUI()
    }
    
    // MARK: - Private
    private func setupUI() {
        self.selectionStyle = .none
        
        self.lblTag.font = Theme.Font.light.withSize(14)
        self.lblTag.textColor = Theme.Dark.textColor
        self.lblTag.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(lblTag)
        
        self.btnAction.rippleColor = UIColor.lightGray
        self.btnAction.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(btnAction)
        
        self.contentView.addConstraints([
            NSLayoutConstraint(item: lblTag, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leadingMargin, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: lblTag, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: btnAction, attribute: .leading, relatedBy: .equal, toItem: lblTag, attribute: .trailing, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: btnAction, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: btnAction, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: btnAction, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: btnAction, attribute: .width, relatedBy: .equal, toItem: btnAction, attribute: .height, multiplier: 1.0, constant: 0)])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let imageView = self.btnAction.imageView {
            imageView.layer.backgroundColor = self.btnAction.rippleColor.cgColor
            let w = imageView.image?.size.width ?? 22.0
            imageView.layer.cornerRadius = w / 2
        }
    }
}

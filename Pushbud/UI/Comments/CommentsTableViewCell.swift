//
//  CommentsTableViewCell.swift
//  PushBud
//
//  Created by Daria.R on 26/04/17.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import UIKit

class CommentsTableViewCell : UITableViewCell {
    
    @IBOutlet var imgUser: AvatarImageView!
    @IBOutlet var lblText: UILabel!
    @IBOutlet var lblDate: UILabel!
    
//    @IBOutlet var lblLikes: UILabel!
//    @IBOutlet var btnLike: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        
//        self.btnLike.setImage(UIImage(named: "like_tiny_off"), for: .normal)
//        self.btnLike.setImage(UIImage(named: "like_tiny_on"), for: .selected)
        
        self.isUserInteractionEnabled = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

//        self.btnLike.layer.removeAllAnimations()
        self.imgUser.reset()
    }
    
}

//
//  PlaceTableViewCell.swift
//  PushBud
//
//  Created by Daria.R on 17/06/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class PlaceTableViewCell: UITableViewCell {

    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblDetail: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }

}

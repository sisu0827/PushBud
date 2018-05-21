//
//  TrackingExpiryDateCell.swift
//  Pushbud
//
//  Created by Daria.R on 11/8/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class TrackingExpiryDateCell: UICollectionViewCell {
    
    var lblTitle: UILabel! // rgb(128,138,147)
    var lblDate: UILabel!
    var darkColor = UIColor(red: 0, green: 22.0/255.0, blue: 39.0/255.0, alpha: 1)
    var highlightColor = UIColor(red: 0/255.0, green: 199.0/255.0, blue: 194.0/255.0, alpha: 1)
    
    override init(frame: CGRect) {
        lblTitle = UILabel(frame: CGRect(x: 5, y: 15, width: frame.width - 10, height: 20))
        lblTitle.font = UIFont.systemFont(ofSize: 10)
        lblTitle.textAlignment = .center
        
        lblDate = UILabel(frame: CGRect(x: 5, y: 30, width: frame.width - 10, height: 40))
        lblDate.font = UIFont.systemFont(ofSize: 25)
        lblDate.textAlignment = .center
        
        super.init(frame: frame)
        
        contentView.addSubview(lblTitle)
        contentView.addSubview(lblDate)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 3
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isSelected: Bool {
        didSet {
            lblTitle.textColor = isSelected ? .white : darkColor.withAlphaComponent(0.5)
            lblDate.textColor = isSelected ? .white : darkColor
            self.contentView.backgroundColor = isSelected ? highlightColor : .white
            self.contentView.layer.borderWidth = isSelected ? 0 : 1
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.isSelected = false
    }
    
    func setData(from date: Date, highlightColor: UIColor, darkColor: UIColor) {
        self.highlightColor = highlightColor
        self.darkColor = darkColor
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        lblTitle.text = dateFormatter.string(from: date).uppercased()
        lblTitle.textColor = isSelected ? .white : darkColor.withAlphaComponent(0.5)
        
        let numberFormatter = DateFormatter()
        numberFormatter.dateFormat = "d"
        lblDate.text = numberFormatter.string(from: date)
        lblDate.textColor = isSelected ? .white : darkColor
        
        contentView.layer.borderColor = darkColor.withAlphaComponent(0.2).cgColor
        contentView.backgroundColor = isSelected ? highlightColor : .white
    }
    
}

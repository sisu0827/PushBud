//
//  TableViewEx.swift
//  Pushbud
//
//  Created by Daria.R on 08/04/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

extension UITableView {
    
    func reloadSection(_ section: Int) {
        self.reloadSections(IndexSet(integer: section), with: .none)
    }
    
    func setEmptyView(nibName: String, messageText: String, image: UIImage? = nil) {
        let emptyView = UIView()
        guard let contentView: UIView = emptyView.addSubviewFromNib(nibName), let label = contentView.viewWithTag(1) as? UILabel else { return }
        
        label.text = LocStr(messageText)
        if (image != nil), let imageView = contentView.viewWithTag(2) as? UIImageView {
            imageView.image = image
        }
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addConstraints([
            NSLayoutConstraint(item: contentView, attribute: .centerX, relatedBy: .equal, toItem: emptyView, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: contentView, attribute: .centerY, relatedBy: .equal, toItem: emptyView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: contentView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: contentView.frame.width),
            NSLayoutConstraint(item: contentView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: contentView.frame.height)
            
            ])
        self.backgroundView = emptyView
    }

}

extension UITableViewRowAction {
    
    func draw(_ backgroundColor: UIColor, image: UIImage, text: String, font: UIFont, cellHeight: CGFloat, placeholder: String = "\t \t \t") {
        let width = Helper.getTextSize(placeholder, font: UIFont.systemFont(ofSize: 17)).width + (8 * 2)
        let textSize = Helper.getTextSize(text, font: font)
        let imageSize = image.size
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: cellHeight), true, 0);
        
        backgroundColor.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: width, height: cellHeight))
        
        let rect = CGRect(x: (width / 2) - (imageSize.width / 2), y: (cellHeight / 2) - imageSize.height, width: imageSize.width, height: imageSize.height)
        image.draw(in: rect)
        
        let point = CGPoint(x: ((width - textSize.width) / 2) - 2, y: (cellHeight / 2) + 8)
        text.draw(at: point, withAttributes: [NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.white])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if (image == nil) {
            self.title = text
        } else {
            self.title = placeholder
            self.backgroundColor = UIColor(patternImage: image!)
        }
    }
    
}

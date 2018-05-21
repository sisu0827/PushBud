//
//  MapEmptyView.swift
//  Pushbud
//
//  Created by Daria.R on 8/15/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

protocol PopularTagDelegate: class {
    func didTap(popularTag tag: Tag)
}

class PopularTagView: UIView {
    
    fileprivate var tags: [Tag]!
    let button = UIButton()
    
    weak var delegate: PopularTagDelegate?
    
    func setup(with tags: [Tag]) -> UIButton {
        self.translatesAutoresizingMaskIntoConstraints = false

        let textView = AutoHeightTextView()
        textView.backgroundColor = UIColor.clear
        textView.font = Theme.Font.medium.withSize(14)
        textView.heightConstraint = NSLayoutConstraint(item: textView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
        textView.isEditable = false
        textView.textAlignment = .center
        textView.textColor = UIColor.darkGray
        textView.isScrollEnabled = false
        textView.bounces = false
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(textView)
        textView.addConstraint(textView.heightConstraint!)

        var location = 0
        var names = [String]()
        var ranges: [(id: Int, start: Int, end: Int)] = []
        for tag in tags {
            names.append("#" + tag.name)
            let length = tag.name.characters.count + 1
            ranges.append((tag.id, location, length))
            location += length + 2
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attrString = NSMutableAttributedString(string: names.joined(separator: ", "), attributes: [
            NSForegroundColorAttributeName: textView.textColor!,
            NSFontAttributeName: textView.font!,
            NSParagraphStyleAttributeName: paragraphStyle])
        ranges.forEach {
            attrString.addAttribute(NSLinkAttributeName, value: "\($0.id):", range: NSRange(location: $0.start, length: $0.end))
        }
        textView.attributedText = attrString
        textView.delegate = self
        
        self.button.contentEdgeInsets = UIEdgeInsetsMake(10, 20, 10, 20)
        self.button.setTitleColor(Theme.Dark.button, for: .normal)
        self.button.setBackgroundImage(UIColor(white: 0, alpha: 0.04).toImage, for: .highlighted)
        self.button.titleLabel!.font = Theme.Font.bold.withSize(13)
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(button)
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[tv]-0-|", options: [], metrics: nil, views: ["tv": textView]))
        self.addConstraints([
            NSLayoutConstraint(item: textView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: button, attribute: .top, relatedBy: .equal, toItem: textView, attribute: .bottom, multiplier: 1.0, constant: 6),
            NSLayoutConstraint(item: button, attribute: .trailing, relatedBy: .equal, toItem: self, attribute:.trailing, multiplier: 1.0, constant: 6),
            NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: button, attribute: .bottom, multiplier: 1.0, constant: 0)
        ])
        self.tags = tags
        
        let btnHide = UIButton()
        btnHide.contentEdgeInsets = UIEdgeInsetsMake(10, 20, 10, 20)
        btnHide.setTitleColor(Theme.Dark.button, for: .normal)
        btnHide.setBackgroundImage(button.backgroundImage(for: .highlighted), for: .highlighted)
        btnHide.titleLabel!.font = Theme.Font.bold.withSize(13)
        btnHide.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(btnHide)
        self.addConstraints([
            NSLayoutConstraint(item: btnHide, attribute: .top, relatedBy: .equal, toItem: button, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: btnHide, attribute:.trailing, relatedBy: .equal, toItem:button, attribute:.leading, multiplier: 1.0, constant: 16)
        ])
        
        return btnHide
    }
    
}

// MARK: - TextView delegate
extension PopularTagView: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if URL.scheme != nil, let tagId = Int(URL.scheme!), let tag = self.tags.filter({ $0.id == tagId }).first {
            self.delegate?.didTap(popularTag: tag)
        }
        return false
    }
    
}

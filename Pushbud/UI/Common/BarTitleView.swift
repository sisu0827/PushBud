//
//  BarTitleView.swift
//  Martoff
//
//  Created by Daria.R on 18/01/16.
//  Copyright © 2017 Martoff. All rights reserved.
//

import UIKit

class BarTitleView: UIView {

    private let textColor: UIColor?
    
    private var titleLabel = UILabel()
    private var subtitleLabel = UILabel()

    private let barbuttonSize: CGFloat = 44.0
    private let maxWidth = CGFloat(150)
    private let smallTitleFont = Theme.Font.medium.withSize(15)
    private let normalTitleFont = Theme.Font.medium.withSize(17)

    //
    //  MARK: - Initialization
    //
    required init(title: String, subtitle: String, textColor: UIColor? = nil) {
        self.textColor = textColor
        
        super.init(frame: CGRect(x: 0, y: 0, width: maxWidth, height: self.barbuttonSize))
        self.setupSubviews()
        self.setTitle(title)
        self.setSubtitle(subtitle)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        self.titleLabel.font = smallTitleFont
        self.titleLabel.textColor = self.textColor ?? Theme.Dark.textColor
        self.titleLabel.textAlignment = .center
        self.addSubview(self.titleLabel)

        self.subtitleLabel.font = Theme.Font.light.withSize(12)
        self.subtitleLabel.textColor = self.textColor ?? Theme.Dark.textColor
        self.subtitleLabel.textAlignment = .center
        self.addSubview(self.subtitleLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.titleLabel.sizeToFit()
        self.titleLabel.fillWidth()
        if self.subtitleLabel.isHidden {
            self.titleLabel.setY(0)
            self.titleLabel.fillHeight()
        } else {
            self.titleLabel.alignBottomWithMargin(self.frame.height / 2)
        }
        
        self.subtitleLabel.sizeToFit()
        self.subtitleLabel.setY(self.titleLabel.frame.maxY)
        self.subtitleLabel.fillWidth()
    }

    //
    //  MARK: - Public Methods
    //
    func title() -> String? {
        return self.titleLabel.text
    }
    
    func setTitle(_ text: String?) {
        self.titleLabel.text = text
        self.setProperWidth()
    }
    
    func subtitle() -> String? {
        return self.subtitleLabel.text
    }

    func setSubtitle(_ text: String?) {
        self.subtitleLabel.text = text
        if (text == nil) {
            self.titleLabel.font = normalTitleFont
            self.subtitleLabel.isHidden = true
        } else {
            self.titleLabel.font = smallTitleFont
            self.subtitleLabel.isHidden = false
        }
        self.setProperWidth()
    }
    
    //
    //  MARK: - Private Methods
    //
    private func setProperWidth() {
        let titleLabelWidth = self.titleLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width
        var subtitleLabelWidth = self.subtitleLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width
        if self.subtitleLabel.isHidden {
            subtitleLabelWidth = 0
        }
        var finalWidth = maxWidth
        if titleLabelWidth > subtitleLabelWidth {
            finalWidth = titleLabelWidth
        } else if subtitleLabelWidth < finalWidth {
            finalWidth = subtitleLabelWidth
        }
        self.frame.size.width = finalWidth
        self.layoutSubviews()
    }
}

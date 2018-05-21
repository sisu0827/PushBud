//
//  GradientView.swift
//  Pushbud
//
//  Created by Daria.R on 31/10/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class GradientView: UIView {

    var gradientColors: [CGColor]? {
        set {
            self.gradientLayer.colors = newValue
            self.update()
        }
        get { return nil }
    }
    var isHorizontal = false {
        didSet {
            self.update()
        }
    }
    
    private let gradientLayer = CAGradientLayer()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.gradientLayer.frame = self.bounds
        self.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.gradientLayer.frame = self.bounds
    }
    
    // MARK: - Private
    private func update() {
        self.gradientLayer.locations = [0.0, 1.0]
        if (self.isHorizontal) {
            self.gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
            self.gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        } else {
            self.gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
            self.gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        }
    }
    
}

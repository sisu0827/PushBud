//
//  CameraViewController.swift
//  Martoff
//
//  Created by Daria.R on 21/12/16.
//  Copyright © 2017 Martoff. All rights reserved.
//

import UIKit

class ShutterButton: UIButton {
    
    let overlayView = UIView()
    let roundLayer = CAShapeLayer()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Highlight
    override var isHighlighted: Bool {
        didSet {
            overlayView.backgroundColor = isHighlighted ? UIColor.gray : UIColor.white
        }
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        overlayView.frame = bounds.insetBy(dx: 3, dy: 3)
        overlayView.layer.cornerRadius = overlayView.frame.size.width/2
        
        roundLayer.path = UIBezierPath(ovalIn: bounds.insetBy(dx: 3, dy: 3)).cgPath
        layer.cornerRadius = bounds.size.width/2
    }
    
    // MARK: - Setup
    func setup() {
        self.backgroundColor = .white
        
        self.overlayView.backgroundColor = UIColor.white
        self.overlayView.isUserInteractionEnabled = false
        self.addSubview(overlayView)

        self.roundLayer.strokeColor = UIColor(red: 0.211765, green: 0.219608, blue: 0.243137, alpha: 1.0).cgColor // 36383e
        self.roundLayer.lineWidth = 2
        self.roundLayer.fillColor = nil
        self.layer.addSublayer(roundLayer)
    }
}

//
//  ColorView.swift
//  Pushbud
//
//  Created by Daria.R on 4/25/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

protocol ColorAnimatable {
    
    var colorView: ColorView? { get }
    
    func animPrepare()
    func animStart()
    func animStop()
}

extension ColorAnimatable where Self: UIView {
    
    func animPrepare() {
        guard let colorView = colorView else { return }
        
        addSubview(colorView)
        colorView.frame = bounds
        colorView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        colorView.layer.cornerRadius = layer.cornerRadius
        colorView.width = colorView.frame.width * 0.75
    }
    
    func animStart() {
        colorView?.startAnimating()
    }
    
    func animStop() {
        colorView?.stopAnimating()
    }
}

class ColorView: UIView {
    
    // Mark: - Public props
    var width: CGFloat = 96.0 {
        didSet {
            setupUI()
        }
    }
    
    public var duration: TimeInterval = 1.5 {
        didSet {
            setupUI()
        }
    }
    
    public var color: UIColor = Theme.Dark.tint {
        didSet {
            setupUI()
        }
    }
    
    // Mark: - Private props
    private let colorMask = CAGradientLayer()
    private let animation = CABasicAnimation(keyPath: "locations")
    private let animationKey = "colorAnimity"
    
    private var size: CGFloat {
        return frame.size.width != 0 ? self.width / frame.width : 0
    }
    
    private var startLocations: [CGFloat] {
        return [-self.size, -self.size / 2, 0]
    }
    
    private var endLocations: [CGFloat] {
        return [1, (1 + self.size / 2), 1 + self.size]
    }
    
    // MARK: - Lifecycle
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupUI()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
 
        self.colorMask.frame = bounds
    }
    
    // MARK: - Public
    public func startAnimating() {
        if self.colorMask.animation(forKey: animationKey) != nil {
            stopAnimating()
        }
        
        layer.mask = self.colorMask
        self.colorMask.add(animation, forKey: animationKey)
        alpha = 1
    }
    
    public func stopAnimating() {
        layer.mask = nil
        self.colorMask.removeAnimation(forKey: animationKey)
        alpha = 0
    }
    
    // MARK: - Private
    private func setupUI() {
        backgroundColor = UIColor(white: 1, alpha: 0.8)
        configureGradientMask()
        configureAnimation()
    }
    
    private func configureGradientMask() {
        let edgeColor = self.color.withAlphaComponent(0)
        let startLocations = [-self.size, -self.size / 2, 0]
        
        self.colorMask.colors = [edgeColor.cgColor, self.color.cgColor, edgeColor.cgColor]
        self.colorMask.locations = startLocations as [NSNumber]?
        self.colorMask.startPoint = CGPoint(x: -self.size, y: 0.3)
        self.colorMask.endPoint = CGPoint(x: 1 + self.size, y: 0.7)
    }
    
    private func configureAnimation() {
        animation.fromValue = startLocations
        animation.toValue = endLocations
        animation.repeatCount = HUGE
        animation.duration = self.duration
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
    }
}

class ColorCircleView: UIView {
    
    var lineWidth: CGFloat = 3 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var color: UIColor = .white {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        
        let drect = CGRect(x: lineWidth / 2, y: lineWidth / 2, width: rect.width - lineWidth, height: rect.height - lineWidth)
        
        let bpath: UIBezierPath = UIBezierPath(ovalIn: drect)
        
        color.set()
        bpath.lineWidth = lineWidth
        bpath.stroke()
    }
}

//
//  TickView.swift
//  Pushbud
//
//  Created by Daria.R on 08/04/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class TickView: UIView {
    private let tickLayer = CAShapeLayer()
    private var tickPoints: [CGPoint] {
        get {
            return [CGPoint(x: 0.67 * bounds.width, y: 0.4 * bounds.height),
                    CGPoint(x: 0.44 * bounds.width, y: 0.59 * bounds.height),
                    CGPoint(x: 0.34 * bounds.width, y: 0.5 * bounds.height)]
        }
    }

    //MARK:- Inits
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(tickLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.addSublayer(tickLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        tickLayer.fillColor = UIColor.clear.cgColor
        tickLayer.lineWidth = 4
        tickLayer.strokeColor = UIColor.white.cgColor
        tickLayer.path = tickPath(true)
        tickLayer.strokeEnd = CGFloat(false)
    }

    private func tickPath(_ flag: Bool) -> CGMutablePath {
        let points = flag ? tickPoints.reversed() : tickPoints
        return points.reduce(CGMutablePath()) { (path, point) -> CGMutablePath in
            if path.isEmpty {
                let path = CGMutablePath()
                path.move(to: point)
                return path
            }

            path.addLine(to: point)
            return path
        }
    }
    
    func toggle(_ show: Bool) {
        tickLayer.path = tickPath(show)
    
        let oldProgress = tickLayer.strokeEnd
        tickLayer.strokeEnd = show ? 1 : 0

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = oldProgress
        animation.duration = 0.15
        tickLayer.add(animation, forKey: "strokeEnd")
    }
}

//
//  DropMenuView.swift
//  Pushbud
//
//  Created by Daria.R on 22/10/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class DropMenuView: UIView {

    let contentView = UIView()
    private let cellHeight: CGFloat
    
    private var backgroundEffectView: UIVisualEffectView?

    private var closeAtPoint: CGPoint?
    private var menuSize: CGSize!

    init(target: Any, actions: [(tag: Int, text: String, color: UIColor?)], selector: Selector, cellHeight: CGFloat = 40, withEffect style: UIBlurEffectStyle? = nil) {
        self.cellHeight = cellHeight
        
        super.init(frame: .zero)
        
        self.addSubview(contentView)
        self.addTarget(target: self, action: #selector(hide))
        self.backgroundColor = UIColor.clear
        
        var yPos: CGFloat = 0
        var maxWidth: CGFloat = 0
        var cells = [UIView]()
        let xPadding: CGFloat = 8.0
        
        for action in actions {
            let button = UIButton(frame: CGRect(x: 0, y: yPos, width: 0, height: 0))
            button.tag = action.tag
            button.contentHorizontalAlignment = .left
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: xPadding, bottom: 0, right: xPadding)
            button.addTarget(target, action: selector, for: .touchUpInside)
            button.layer.masksToBounds = true
            button.setTitle(action.text, for: .normal)
            button.titleLabel?.font = Theme.Font.light.withSize(16)
            button.setTitleColor(action.color ?? Theme.Dark.textColor, for: .normal)
            button.sizeToFit()
            if (button.frame.width > maxWidth) {
                maxWidth = button.frame.width
            }
            cells.append(button)
            self.contentView.addSubview(button)
            
            yPos += cellHeight
        }
        
        maxWidth += xPadding * 2
        self.menuSize = CGSize(width: maxWidth, height: yPos)

        for i in 1..<cells.count {
            let separator = CALayer()
            separator.backgroundColor = Theme.Light.separator
            separator.frame.size = CGSize(width: maxWidth, height: 1.0)
            cells[i].layer.addSublayer(separator)
        }

        // Background
        if (style == nil) {
            self.contentView.layer.backgroundColor = UIColor.white.cgColor
            self.contentView.layer.borderWidth = 0.5
            self.contentView.layer.borderColor = Theme.Light.separator
        } else {
            self.backgroundEffectView = self.getBlurEffectView(style!)
            self.contentView.insertSubview(self.backgroundEffectView!, at: 0)
        }

        // Shadow
        self.contentView.layer.masksToBounds = false
        self.contentView.layer.shadowColor = UIColor.gray.cgColor
        self.contentView.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        self.contentView.layer.shadowOpacity = 0.3
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public
    func setBlurEffectView(with style: UIBlurEffectStyle, afterDelay: Double) {
        let effectView = self.getBlurEffectView(style)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + afterDelay) {
            self.backgroundEffectView?.removeFromSuperview()
            self.backgroundEffectView = effectView
            self.contentView.insertSubview(effectView, at: 0)
        }
    }
    
    func show(in view: UIView, buttonRect: CGRect, margin: CGFloat = 0) {
        guard self.closeAtPoint == nil else { return }

        self.frame = CGRect(origin: .zero, size: view.frame.size)
        view.addSubview(self)

        var destPoint = CGPoint(x: buttonRect.origin.x, y: buttonRect.origin.y + buttonRect.height + margin)
        self.contentView.frame.origin = destPoint
        if (!self.bounds.contains(CGRect(origin: destPoint, size: menuSize))) {
            let right = destPoint.x + menuSize.width
            if (right > self.frame.width) {
                self.contentView.frame.origin.x = buttonRect.origin.x + buttonRect.width
                destPoint.x -= (menuSize.width - buttonRect.width)
            }
            
            let bottom = destPoint.y + menuSize.height
            if (bottom > self.frame.height) {
                let yPos = buttonRect.origin.y - margin
                self.contentView.frame.origin.y = yPos
                destPoint.y = yPos - menuSize.height
            }
        }
        
        self.closeAtPoint = self.contentView.frame.origin
        
        UIView.animate(withDuration: 0.4) { [weak self] in
            guard let _self = self else { return }
            
            _self.contentView.frame = CGRect(origin: destPoint, size: _self.menuSize)
            _self.contentView.alpha = 1.0
            
            let size = CGSize(width: _self.menuSize.width, height: _self.cellHeight)
            for view in _self.contentView.subviews {
                view.frame.size = size
            }
        }
    }
    
    func hide() {
        guard let point = self.closeAtPoint else { return }
        
        self.closeAtPoint = nil
        
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            guard let contentView = self?.contentView else { return }
            
            contentView.frame = CGRect(origin: point, size: .zero)
            contentView.alpha = 0
            for view in contentView.subviews {
                view.frame.size = .zero
            }
        }) {  [weak self] _ in
            self?.removeFromSuperview()
        }
    }
    
    // MARK: - Private
    private func getBlurEffectView(_ style: UIBlurEffectStyle) -> UIVisualEffectView {
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: style))
        effectView.frame = self.bounds
        effectView.layer.cornerRadius = self.bounds.width/2
        effectView.clipsToBounds = true
        effectView.backgroundColor = .clear
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return effectView
    }
    
}

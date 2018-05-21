//
//  AvatarImageView.swift
//  PushBud
//
//  Created by Daria.R on 4/25/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class AvatarImageView: UIView, ColorAnimatable {
    
    @IBInspectable var targetSize: CGFloat = 0.0
    var colorView: ColorView? = ColorView()
    
    var image: UIImage? {
        set { self.imageView.image = newValue }
        get { return self.imageView.image }
    }
    private let imageView = URLImageView()
    private let circleView = ColorCircleView()

    private let _colorOverlay = UIView()
    private let _whiteOverlay = UIView()
    
    override func awakeFromNib() {
        super.awakeFromNib()

        _colorOverlay.alpha = 0.85
        _colorOverlay.backgroundColor = self.backgroundColor
        _colorOverlay.isOpaque = false
        _colorOverlay.tag = 9
        colorView?.insertSubview(_colorOverlay, at: 0)
        
        _whiteOverlay.backgroundColor = UIColor(white: 0.97, alpha: 0.5)
        _whiteOverlay.isOpaque = false
        _whiteOverlay.tag = 8
        colorView?.insertSubview(_whiteOverlay, at: 0)
        
        backgroundColor = .clear
        addCircleView()
        addImageView()
    }
    
    private func configureAnimation() {
        self.animPrepare()
        colorView?.backgroundColor = UIColor(white: 1, alpha: 0.1)
        colorView?.color = UIColor(white: 1, alpha: 0.8)
        colorView?.duration = 2
    }
    
    private func addCircleView() {
        circleView.backgroundColor = .clear
        addSubview(circleView)
        circleView.frame = bounds
        circleView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    private func addImageView() {
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(imageView)
        addConstraint(NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
        
        addConstraint(NSLayoutConstraint(item: imageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        addConstraint(NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: -2))
        
        addConstraint(NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: -2))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self._colorOverlay.frame = bounds
        self._whiteOverlay.frame = bounds

        self.layer.cornerRadius = bounds.size.height / 2

        colorView.map {
            $0.layer.cornerRadius = $0.bounds.size.height / 2
        }
    }
    
    private var placeholderLabel: UILabel?

    func setupAvatar(_ pictureUrl: String?, text: String?, textColor: UIColor? = .white, animated: Bool = false) {
        let size = targetSize > 0 ? targetSize : self.bounds.size.width

        if (!self.clipsToBounds) {
            self.imageView.clipsToBounds = true
            self.imageView.layer.cornerRadius = size / 2
            self.clipsToBounds = true
        }

        guard let filename = pictureUrl else {
            if (textColor != nil) {
                self.showPlaceholder(text ?? "", textColor: textColor!, textSize: size)
            }
            return
        }

        if (self.placeholderLabel != nil) {
            self.placeholderLabel!.removeFromSuperview()
            self.placeholderLabel = nil
        }

        if (animated) {
            if let colorView = self.colorView, colorView.superview == nil {
                self.configureAnimation()
            }
            self.animStart()
        }
        
        self.download("\(Int(size) * 3)/" + filename, text: text ?? "", textColor: textColor, textSize: size)
    }

    func reset() {
        self.imageView.reset()
        if (self.placeholderLabel != nil) {
            self.placeholderLabel!.removeFromSuperview()
            self.placeholderLabel = nil
        }
    }
    
    private func download(_ pictureUrl: String, text: String, textColor: UIColor?, textSize: CGFloat) {
        ImageClient.shared.download(pictureUrl) { [weak self] (image, imageUrl, isCached) in
            
            self?.animStop()
            
            guard image != nil else {
                if (textColor != nil) {
                    self?.showPlaceholder(text, textColor: textColor!, textSize: textSize)
                }
                return
            }
            guard imageUrl == pictureUrl else { return }
            guard (!isCached), let imageView = self?.imageView else {
                self?.imageView.image = image
                return
            }
            
            UIView.transition(with: imageView, duration: 0.6, options: .transitionCrossDissolve, animations: {
                imageView.image = image
            }, completion: nil)
        }
    }

    func removePlaceholder() {
        self.placeholderLabel?.removeFromSuperview()
        self.placeholderLabel = nil
    }
    
    private func showPlaceholder(_ name: String, textColor: UIColor, textSize: CGFloat, collectFirstLetters: Bool = true) {
        if self.placeholderLabel == nil {
            let label = UILabel(frame: self.bounds)
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.1
            label.font = UIFont.systemFont(ofSize: self.imageView.layer.cornerRadius)
            label.textColor = textColor
            label.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(label)
            self.placeholderLabel = label
            self.addConstraints([
                NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: label, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 0.66, constant: 0)
            ])

        }

        if (name.isEmpty) {
            self.placeholderLabel!.text = "?"
        } else if (collectFirstLetters) {
            self.placeholderLabel!.text = name.capitalized.components(separatedBy: " ").reduce("") { $0.0 + String($0.1.characters.first!) }
        } else {
            self.placeholderLabel!.text = name
        }
    }
    
}

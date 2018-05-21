//
//  ImageEx.swift
//  Pushbud
//
//  Created by Daria.R on 08/04/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

extension CGImage {

    func convert(to orientation: UIImageOrientation, size: CGSize) -> UIImage {
        guard orientation != .up else { return UIImage(cgImage: self, scale: 1, orientation: .up) }

        var transform = CGAffineTransform.identity
        
        if (orientation == .down || orientation == .downMirrored) {
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
        }
        else if (orientation == .left || orientation == .leftMirrored) {
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2)
        }
        else if (orientation == .right || orientation == .rightMirrored) {
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -(CGFloat.pi / 2))
        }
        
        if (orientation == .upMirrored || orientation == .downMirrored) {
            transform = transform.translatedBy(x: size.width, y: 0);
            transform = transform.scaledBy(x: -1, y: 1)
        }
        else if (orientation == .leftMirrored || orientation == .rightMirrored) {
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        }
        
        guard let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: self.bitsPerComponent, bytesPerRow: 0, space: self.colorSpace!, bitmapInfo: self.bitmapInfo.rawValue)
        else {
            return UIImage(cgImage: self, scale: 1, orientation: orientation)
        }
        
        ctx.concatenate(transform)
        
        switch (orientation) {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(self, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(self, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }

        return UIImage(cgImage: ctx.makeImage() ?? self, scale: 1, orientation: .up)
    }
}

extension UIImage {
    
    func resize(to targetSize: CGSize) -> UIImage? {
        let scaleX  = targetSize.width  / self.size.width
        let scaleY = targetSize.height / self.size.height
        
        var newSize: CGSize
        if(scaleX > scaleY) {
            newSize = CGSize(width: size.width * scaleY, height: size.height * scaleY)
        } else {
            newSize = CGSize(width: size.width * scaleX, height: size.height * scaleX)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func toCircle(isScaledImage: Bool = false, borderWidth: CGFloat = 1.0, borderColor: UIColor = .lightGray) -> UIImage {
        let scale = UIScreen.main.scale
        let imageWH: CGFloat
        if (isScaledImage) {
            imageWH = scale > 1.0 ? size.width * scale : size.width
        } else {
            imageWH = scale > 1.0 ? size.width / scale : size.width
        }

        let ovalSize = imageWH + (borderWidth * 2)
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: ovalSize, height: ovalSize), false, Constants.screenScale)
        
        // Border circle
        let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: ovalSize, height: ovalSize))
        borderColor.set()
        path.fill()
        
        // Crop area
        UIBezierPath(ovalIn: CGRect(x: borderWidth, y: borderWidth, width: imageWH, height: imageWH)).addClip()

        self.draw(in: CGRect(x: borderWidth, y: borderWidth, width: imageWH, height: imageWH))
        let clipImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        return clipImage ?? self
    }
    
}

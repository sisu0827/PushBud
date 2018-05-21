//
//  GalleryCell.swift
//  Pushbud
//
//  Created by Daria.R on 7/06/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class GalleryCell: UICollectionViewCell, UIScrollViewDelegate {
    
    var image: UIImage? {
        set {
            self.imageView.image = newValue
            
            guard let size = newValue?.size else { return }
            
            self.imageView.sizeToFit()
            self.setZoomScale(imageSize: size)
        }
        get { return nil; }
    }
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private var currentUri: String?
    private let indicatorTag = 342

    // MARK : - Life Cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.bouncesZoom = true
        self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(self.scrollView)
        Helper.addConstraints(["H:|-0-[sv]-0-|", "V:|-0-[sv]-0-|"], source: self.contentView, views: ["sv":self.scrollView])
        
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.addSubview(self.imageView)
        Helper.addConstraints(["H:|-0-[iv]-0-|", "V:|-0-[iv]-0-|"], source: self.scrollView, views: ["iv":self.imageView])
        
        self.scrollView.delegate = self
        self.setupGestureRecognizer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func downloadImage(_ uri: String) {
        guard (self.currentUri != uri) else { return }
        
        self.currentUri = uri
        
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinner.frame = self.contentView.frame
        spinner.tag = self.indicatorTag
        self.contentView.addSubview(spinner)
        spinner.startAnimating()
        
        ImageClient.shared.download(uri) { [weak self] image, url, loadedFromCache in
            if (self?.currentUri == url) {
                self!.postDownload(image)
            }
        }
    }
    
    private func postDownload(_ image: UIImage?) {
        self.contentView.viewWithTag(self.indicatorTag)?.removeFromSuperview()
        
        self.imageView.alpha = 0
        self.image = image
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.imageView.alpha = 1
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.contentView.viewWithTag(indicatorTag)?.removeFromSuperview()
        self.imageView.image = nil
        self.currentUri = nil
    }
    
    func doubleTapAction(_ recognizer: UITapGestureRecognizer) {
        if (scrollView.zoomScale > scrollView.minimumZoomScale) {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            scrollView.setZoomScale(scrollView.maximumZoomScale, animated: true)
        }
    }
    
    // MARK: UIScrollViewDelegate Methods
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.centerImage()
    }
    
    func centerImage() {
        let imageViewSize = imageView.frame.size
        let viewSize = contentView.bounds.size
        
        let yPad = imageViewSize.height < viewSize.height ? (viewSize.height - imageViewSize.height) / 2 : 0
        let xPad = imageViewSize.width < viewSize.width ? (viewSize.width - imageViewSize.width) / 2 : 0
        
        if yPad >= 0 {
            // Center the image on screen
            scrollView.contentInset = UIEdgeInsets(top: yPad, left: xPad, bottom: yPad, right: xPad)
        } else {
            // Limit the image panning to the screen bounds
            scrollView.contentSize = imageViewSize
        }
    }
    
    // MARK: Private Methods
    private func setupGestureRecognizer() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(GalleryCell.doubleTapAction(_:)))
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)
    }
    
    private func setZoomScale(imageSize: CGSize) {
        let viewSize = self.contentView.bounds.size
        
        let imageSize = self.imageView.image!.size
        
        // calculate min/max zoomscale
        let xScale = viewSize.width / imageSize.width    // the scale needed to perfectly fit the image width-wise
        let yScale = viewSize.height / imageSize.height  // the scale needed to perfectly fit the image height-wise
        var minScale = min(xScale, yScale)                 // use minimum of these to allow the image to become fully visible
        
        // on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
        // maximum zoom scale to 0.5.
        let maxScale = 1.0 * UIScreen.main.scale
        
        // don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.)
        if minScale > maxScale {
            minScale = maxScale
        }
        
        self.scrollView.maximumZoomScale = maxScale
        self.scrollView.minimumZoomScale = minScale
        self.scrollView.zoomScale = minScale
    }
    
}

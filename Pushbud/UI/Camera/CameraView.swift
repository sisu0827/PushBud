//
//  CameraViewController.swift
//  Martoff
//
//  Created by Daria.R on 21/12/16.
//  Copyright © 2017 Martoff. All rights reserved.
//

import UIKit
import AVFoundation

protocol CameraViewDelegate: class {
    func cameraView(_ cameraView: CameraView, didTouch point: CGPoint)
}

class CameraView: UIView, UIGestureRecognizerDelegate {
    
    let rotateOverlayView = UIView()
    let shutterOverlayView = UIView()
    let btnShutter = ShutterButton()
    
    private let btnClose = UIButton()
    private let btnRotate = UIButton()
    
    let btnResize = UIButton()
    private let btnResizeHeight: NSLayoutConstraint
    
    private let bottomContainer = UIView()
    private let focusImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 110, height: 110))
    
    private var timer: Timer?
    var previewLayer: AVCaptureVideoPreviewLayer?
    private weak var delegate: CameraViewDelegate?
    
    let btnFlash = UIButton()
    
    // MARK: - Initialization
    
    init(target: Any) {
        self.btnResizeHeight = NSLayoutConstraint(item: btnResize, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 60)
        
        super.init(frame: CGRect.zero)
        
        self.delegate = target as? CameraViewDelegate
        self.backgroundColor = Theme.Dark.background
        
        self.btnClose.setImage(UIImage(named: "close_big"), for: .normal)
        self.btnClose.pbAddShadow()
        self.btnClose.addTarget(target, action: #selector(CameraViewController.closeAction), for: .touchUpInside)
        self.btnClose.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.btnClose)
        Helper.addConstraints(["H:|-16-[btn]", "V:|-16-[btn(44)]", "[btn(44)]"], source: self, views: ["btn" : self.btnClose])

        //
        self.btnFlash.setImage(UIImage(named: "camera_flash")?.withRenderingMode(.alwaysTemplate), for: .normal)
        self.btnFlash.pbAddShadow()
        self.btnFlash.tintColor = .white
        self.btnFlash.addTarget(target, action: #selector(CameraViewController.flashAction), for: .touchUpInside)
        self.btnFlash.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.btnFlash)
        
        Helper.addConstraints(["V:[btn(44)]", "[btn(44)]"], source: self, views: ["btn" : btnFlash])
        self.addConstraints([
            NSLayoutConstraint(item: self.btnFlash, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.btnFlash, attribute: .centerY, relatedBy: .equal, toItem: btnClose, attribute: .centerY, multiplier: 1.0, constant: 0)
            ])
        
        btnRotate.setImage(UIImage(named: "camera_toggle"), for: .normal)
        btnRotate.pbAddShadow()
        btnRotate.addTarget(target, action: #selector(CameraViewController.rotateButtonTouched(_:)), for: .touchUpInside)
        btnRotate.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(btnRotate)
        Helper.addConstraints(["H:[btn]-16-|", "V:|-16-[btn(44)]", "[btn(44)]"], source: self, views: ["btn" : btnRotate])
        
        //
        self.bottomContainer.backgroundColor = UIColor(white: 0, alpha: 0.1)
        self.bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.bottomContainer)
        Helper.addConstraints(["H:|-0-[bc]-0-|", "V:[bc(80)]-0-|"], source: self, views: ["bc" : self.bottomContainer])
        
        //
        btnShutter.pbAddShadow()
        btnShutter.addTarget(target, action: #selector(CameraViewController.shutterButtonTouched(_:)), for: .touchUpInside)
        btnShutter.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.addSubview(btnShutter)
        
        let views: [String:Any] = ["bc":bottomContainer, "bs":btnShutter]
        Helper.addConstraints(["V:[bc]-(<=1)-[bs]"], source: bottomContainer, views: views, options: .alignAllCenterX)
        Helper.addConstraints(["H:[bc]-(<=1)-[bs]"], source: bottomContainer, views: views, options: .alignAllCenterY)
        Helper.addConstraints(["[bs(60)]", "V:[bs(60)]"], source: bottomContainer, views: ["bs":btnShutter], options: .alignAllCenterY)
        
        //
        btnResize.addTarget(self, action: #selector(resizeView), for: .touchUpInside)
        btnResize.setTitle("9:16", for: .normal)
        btnResize.setTitleColor(UIColor.white, for: .normal)
        btnResize.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        btnResize.translatesAutoresizingMaskIntoConstraints = false
        btnResize.layer.borderColor = Theme.Dark.tint.cgColor
        btnResize.layer.borderWidth = 1.0
        bottomContainer.addSubview(btnResize)
        Helper.addConstraints(["H:|-24-[Btn]", "[Btn(40)]"], source: bottomContainer, views: ["Btn" : btnResize])
        let btnResizeY = NSLayoutConstraint(item: btnResize, attribute: .centerY, relatedBy: .equal, toItem: bottomContainer, attribute: .centerY, multiplier: 1.0, constant: 0)
        bottomContainer.addConstraints([btnResizeHeight,btnResizeY])
        
        //
        rotateOverlayView.alpha = 0
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        rotateOverlayView.addSubview(blurView)
        
        self.insertSubview(rotateOverlayView, belowSubview: btnRotate)
        
        rotateOverlayView.translatesAutoresizingMaskIntoConstraints = false
        Helper.addConstraints(["H:|-0-[rov]-0-|", "V:|-0-[rov]-0-|"], source: self, views: ["rov" : rotateOverlayView])
        
        blurView.translatesAutoresizingMaskIntoConstraints = false
        Helper.addConstraints(["H:|-0-[bv]-0-|", "V:|-0-[bv]-0-|"], source: rotateOverlayView, views: ["bv" : blurView])
        
        //
        focusImageView.image = UIImage(named: "camera_focus")
        focusImageView.backgroundColor = .clear
        focusImageView.alpha = 0
        self.insertSubview(focusImageView, belowSubview: bottomContainer)
        
        //
        shutterOverlayView.alpha = 0
        shutterOverlayView.backgroundColor = .black
        self.insertSubview(shutterOverlayView, belowSubview: bottomContainer)
        
        shutterOverlayView.translatesAutoresizingMaskIntoConstraints = false
        Helper.addConstraints(["H:|-0-[sov]-0-|", "V:|-0-[sov]-0-|"], source: self, views: ["sov" : shutterOverlayView])
        
        //
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        tapRecognizer.delegate = self
        self.addGestureRecognizer(tapRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.btnResizeHeight = NSLayoutConstraint(item: btnResize, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 60)
        super.init(coder: aDecoder)
    }
    
    private var nextPreviewLayerFrame: CGRect {
        var newFrame = self.bounds
        
        switch (self.btnResize.tag) {
        case 0:
            btnResize.setTitle("3:4", for: .normal)
            newFrame.size.height = newFrame.width + (newFrame.width * 0.25)
            newFrame.origin.y = (self.bounds.height - newFrame.size.height) / 2
            self.btnResize.tag = 1
            self.btnResizeHeight.constant = 50
        case 1:
            btnResize.setTitle("1:1", for: .normal)
            newFrame.size.height = newFrame.width
            newFrame.origin.y = (self.bounds.height - newFrame.size.height) / 2
            self.btnResize.tag = 2
            self.btnResizeHeight.constant = 40
        default:
            btnResize.setTitle("9:16", for: .normal)
            self.btnResize.tag = 0
            self.btnResizeHeight.constant = 60
        }
        
        return newFrame
    }
    
    // MARK: - Setup
    func resizeView() {
        guard self.previewLayer != nil else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.previewLayer!.frame = self.nextPreviewLayerFrame
        CATransaction.commit()
    }
    
    func transform(_ transform: CGAffineTransform?) {
        let t = transform ?? CGAffineTransform.identity
        self.btnClose.transform = t
        self.btnFlash.transform = t
        self.btnRotate.transform = t
        self.btnResize.transform = t
    }
    
    func setupPreviewLayer(_ session: AVCaptureSession, orientation: AVCaptureVideoOrientation) {
        guard previewLayer == nil else { return }

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer?.autoreverses = true
        layer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        self.layer.insertSublayer(layer!, at: 0)
        
        layer?.frame = self.nextPreviewLayerFrame
        layer?.connection.videoOrientation = orientation

        previewLayer = layer
    }
    
    // MARK: - Action
    func viewTapped(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: self)
        
        focusImageView.transform = CGAffineTransform.identity
        timer?.invalidate()
        delegate?.cameraView(self, didTouch: point)
        
        focusImageView.center = point
        
        UIView.animate(withDuration: 0.5, animations: {
            self.focusImageView.alpha = 1
            self.focusImageView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        }, completion: { _ in
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(CameraView.onTimer), userInfo: nil, repeats: false)
        })
    }
    
    // MARK: - Timer
    func onTimer() {
        UIView.animate(withDuration: 0.3, animations: {
            self.focusImageView.alpha = 0
        }, completion: { _ in
            self.focusImageView.transform = CGAffineTransform.identity
        })
    }
    
    // MARK: - UIGestureRecognizerDelegate
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: self)
        
        return point.y > btnClose.frame.maxY
            && point.y < bottomContainer.frame.origin.y
    }
}

//
//  CameraViewController.swift
//  Martoff
//
//  Created by Daria.R on 21/12/16.
//  Copyright © 2017 Martoff. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController, CircleTransitionType {
    
    fileprivate enum AlertAction: Int {
        case exitVC = 1, retrySignin
    }

    var circleView: UIView {
        return self.cameraView?.btnShutter ?? self.view
    }
    
//    var delegate: EditorViewControllerDelegate?
    private let permissionViewTag = 28
    private let pinchRecognizer = UIPinchGestureRecognizer()
    
    // CameraMan
    let session = AVCaptureSession()
    let queue = DispatchQueue(label: "com.pushbud.Camera.SessionQueue", qos: .background)
    
    var backCamera: AVCaptureDeviceInput?
    var frontCamera: AVCaptureDeviceInput?
    var stillImageOutput: AVCaptureStillImageOutput!
    private var zoomFactor: CGFloat = 1
    private var maxZoomFactor: CGFloat!
    fileprivate var imageUrl: URL?
    fileprivate var imageKey: String!


    var currentInput: AVCaptureDeviceInput? {
        return session.inputs.first as? AVCaptureDeviceInput
    }

    var cameraView: CameraView?

    private var videoOrientation: AVCaptureVideoOrientation {
        switch self.orientation {
        case .portrait:
            return .portrait
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    private var orientation: UIDeviceOrientation = .unknown
    
    // MARK: - KVO constants
    private var NextLevelFlashActiveObserverContext = "NextLevelFlashActiveObserverContext"
    
    //
    // MARK: - Life Cycle
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        self.pinchRecognizer.addTarget(self, action: #selector(pinch(_:)))
        self.view.backgroundColor = Theme.Light.background
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.requestSignin()
        
        self.orientation = UIDevice.current.orientation

        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged(_:)), name: .UIDeviceOrientationDidChange, object: nil)
        

        guard (AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) == .authorized) else {
            self.requestAccess()
            return
        }
        
        guard (self.cameraView != nil) else {
            self.postRequest(true)
            return
        }

        self.addInput(self.backCamera!)
    }

    deinit {
        self.session.stopRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        if (self.cameraView != nil) {
            self.cameraView!.removeGestureRecognizer(pinchRecognizer)
            self.removeFlashObserver()
            if (self.currentInput != nil) {
                self.session.removeInput(self.currentInput!)
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        UIView.setAnimationsEnabled(false)
        
        coordinator.animate(alongsideTransition: nil, completion: { context in
            UIView.setAnimationsEnabled(true)
        })
    }
    
    override var shouldAutorotate: Bool {
        return UIDevice.current.orientation == .portrait
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &NextLevelFlashActiveObserverContext {
            let image = UIImage(named: "camera_flash_auto")!
            self.cameraView?.btnFlash.setImage(currentInput?.device.isFlashActive == true ? image : image.withRenderingMode(.alwaysTemplate), for: .normal)
        }
    }
    
    //
    // START FLASH METHODS
    //
    func flashAction() {
        self.toggleFlash()
    }
    
    func toggleFlash(forceOff: Bool = false) {
        guard let device = currentInput?.device, (device.hasFlash && device.isFlashAvailable) else { return }
        
        if (device.flashMode == .auto) {
            self.removeFlashObserver(force: true)
        }
        
        var image = "camera_flash"
        let mode: AVCaptureFlashMode
        
        if (forceOff || device.flashMode == .auto) {
            mode = .off
        }
        else if (device.flashMode == .on) {
            image = "camera_flash_auto"
            mode = .auto
        }
        else {
            mode = .on
        }
        
        if let image = UIImage(named: image) {
            self.cameraView?.btnFlash.setImage(mode == .on ? image : image.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        
        if device.isFlashModeSupported(mode) {
            if (mode == .auto) {
                self.addFlashObserver(force: true)
            }
            queue.async {
                self.lock {
                    device.flashMode = mode
                    print("DeviceMode: \(mode.rawValue)")
                }
            }
        }
    }
    
    //
    // START CAMERAMAN METHODS
    //
    func pinch(_ sender: UIPinchGestureRecognizer) {
        guard self.currentInput == self.backCamera, let device = self.currentInput?.device else { return }
        
        let newZoomFactor = min(sender.scale * self.zoomFactor, self.maxZoomFactor)
        
        if sender.state == .ended {
            self.zoomFactor = max(newZoomFactor, 1)
        }
        
        guard (newZoomFactor > 1) else { return }

        queue.async {
            self.lock {
                device.videoZoomFactor = newZoomFactor
            }
        }
    }
    
    private func addInput(_ input: AVCaptureDeviceInput) {
        configurePreset(input)
        
        guard session.canAddInput(input) else { return }
        
        session.addInput(input)
        
        guard let btnFlash = self.cameraView?.btnFlash else {
            self.cameraView?.removeGestureRecognizer(pinchRecognizer)
            return
        }

        if (self.maxZoomFactor != nil) {
            self.cameraView!.addGestureRecognizer(pinchRecognizer)
        }
        
        if (input.device.hasFlash) {
            var image: UIImage?
            
            switch (input.device.flashMode) {
            case .off:
                image = UIImage(named: "camera_flash")?.withRenderingMode(.alwaysTemplate)
            case .on:
                image = UIImage(named: "camera_flash")
            case .auto:
                image = UIImage(named: "camera_flash_auto")
                self.addFlashObserver(force: true)
            }
            
            DispatchQueue.main.async {
                btnFlash.isHidden = false
                btnFlash.setImage(image, for: .normal)
            }
        } else {
            DispatchQueue.main.async {
                btnFlash.isHidden = true
            }
        }
        
    }
    
    private func configurePreset(_ input: AVCaptureDeviceInput) {
        for asset in preferredPresets() {
            if input.device.supportsAVCaptureSessionPreset(asset) && self.session.canSetSessionPreset(asset) {
                self.session.sessionPreset = asset
                return
            }
        }
    }
    
    private func preferredPresets() -> [String] {
        return [
            AVCaptureSessionPresetHigh,
            AVCaptureSessionPresetMedium,
            AVCaptureSessionPresetLow
        ]
    }
    
    private func addFlashObserver(force: Bool = false) {
        if let device = currentInput?.device, (force || (device.hasFlash && device.flashMode == .auto)) {
            device.addObserver(self, forKeyPath: "flashActive", options: [.new], context: &NextLevelFlashActiveObserverContext)
        }
    }
    
    private func removeFlashObserver(force: Bool = false) {
        if let device = currentInput?.device, (force || (device.hasFlash && device.flashMode == .auto)) {
            device.removeObserver(self, forKeyPath: "flashActive", context: &NextLevelFlashActiveObserverContext)
        }
    }
    
    private func switchCamera(_ isBackCamera: Bool) -> Bool {
        guard let newInput = isBackCamera ? self.frontCamera : self.backCamera else { return false }
        
        self.removeFlashObserver()
        
        defer {
            self.postSwitchCamera()
        }
        
        queue.async {
            self.configure {
                self.session.removeInput(self.currentInput!)
                self.addInput(newInput)
            }
        }
        
        return true
    }
    
    private func postSwitchCamera() {
        guard let overlayView = self.cameraView?.rotateOverlayView else { return }
        
        UIView.animate(withDuration: 0.7, animations: {
            overlayView.alpha = 0
        })
    }
    
    func takePhoto(_ previewLayer: AVCaptureVideoPreviewLayer, completion: @escaping ((CMSampleBuffer?) -> Void)) {
        guard let connection = stillImageOutput?.connection(withMediaType: AVMediaTypeVideo) else { return }
        
        connection.videoOrientation = self.videoOrientation
        
        queue.async {
            self.stillImageOutput?.captureStillImageAsynchronously(from: connection) { buffer, error in

                var response: CMSampleBuffer?
                if (error == nil && buffer != nil && CMSampleBufferIsValid(buffer!)) {
                    response = buffer
                }
                
                DispatchQueue.main.async {
                    completion(response)
                }
            }
        }
    }
    
    fileprivate func setFocus(_ point: CGPoint) {
        guard let device = currentInput?.device , device.isFocusModeSupported(AVCaptureFocusMode.locked) else { return }
        
        queue.async {
            self.lock {
                device.focusPointOfInterest = point
            }
        }
    }
    
    // MARK: - Lock
    func lock(_ block: () -> Void) {
        if let device = currentInput?.device , (try? device.lockForConfiguration()) != nil {
            block()
            device.unlockForConfiguration()
        }
    }
    
    // MARK: - Configure
    func configure(_ block: () -> Void) {
        session.beginConfiguration()
        block()
        session.commitConfiguration()
    }
    // END CAMERAMAN METHODS //
    
    // MARK: - Private
    fileprivate func requestSignin() {
        ImageClient.shared.requestKey(ofType: "event_picture") { [weak self] result in
            
            guard let myself = self else { return }
            
            switch result {
            case .Success(let data):
                myself.imageUrl = data.0
                myself.imageKey = data.1
            case .Failure(let error):
                if (error?.isNetworkError == true) {
                    Helper.alertNoNetRetry(myself, retryCase: AlertAction.retrySignin.rawValue, cancelCase: AlertAction.exitVC.rawValue)
                } else {
                    error?.record()
                }
            }
        }
    }
    
    private func requestAccess() {
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { [weak self] granted in
            DispatchQueue.main.async {
                self?.postRequest(granted)
            }
        }
    }
    
    private func postRequest(_ status: Bool) {
        let permissionView = self.view.viewWithTag(self.permissionViewTag)
        
        if (status) {
            permissionView?.removeFromSuperview()
            self.setupCameraView()
        }
        else if (permissionView == nil) {
            let permission = PermissionView()
            permission.tag = self.permissionViewTag
            permission.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(permission)
            Helper.addConstraints(["H:|-0-[pv]-0-|", "V:|-0-[pv]-0-|"], source: self.view, views: ["pv" : permission])
        }
    }
    
    fileprivate func setupCameraView() {
        // CameraView
        self.cameraView = CameraView(target: self)
        self.cameraView!.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.cameraView!)
        Helper.addConstraints(["H:|-0-[cv]-0-|", "V:|-0-[cv]-0-|"], source: self.view, views: ["cv" : self.cameraView!])
        self.setNeedsStatusBarAppearanceUpdate()
        
        // Devices
        AVCaptureDevice.devices().flatMap {
            return $0 as? AVCaptureDevice
            }.filter {
                return $0.hasMediaType(AVMediaTypeVideo)
            }.forEach {
                switch $0.position {
                case .front:
                    self.frontCamera = try? AVCaptureDeviceInput(device: $0)
                case .back:
                    if let camera = try? AVCaptureDeviceInput(device: $0) {
                        self.backCamera = camera
                        self.maxZoomFactor = $0.activeFormat.videoMaxZoomFactor
                    }
                default:
                    break
                }
        }
        
        guard (self.backCamera != nil || self.frontCamera != nil) else { return }
        
        self.stillImageOutput = AVCaptureStillImageOutput()
        self.stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        
        self.addInput(self.backCamera ?? self.frontCamera!)
        
        if session.canAddOutput(self.stillImageOutput) {
            session.addOutput(self.stillImageOutput)
        }
        
        queue.async {
            self.session.startRunning()
            DispatchQueue.main.async {
                self.cameraView?.setupPreviewLayer(self.session, orientation: self.videoOrientation)
            }
        }
    }
    
    // MARK: - Action
    func orientationChanged(_ note: Notification) {
        guard let orientation = Helper.newOrientation(new: (note.object as! UIDevice).orientation, old: self.orientation) else { return }
        
        self.orientation = orientation
        
        if (self.cameraView != nil) {
            performSelector(onMainThread: #selector(rotateView), with: nil, waitUntilDone: true)
        }
    }
    
    func rotateView() {
        UIView.animate(withDuration: 0.5, animations: {[weak self] in
            self?.transformViews()
        })
    }
    
    private func transformViews() {
        var transform: CGAffineTransform?
        switch self.orientation {
        case .portraitUpsideDown:
            transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        case .landscapeLeft:
            transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        case .landscapeRight:
            transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        default:
            break
        }
        
        self.cameraView?.transform(transform)
    }
    
    func closeAction() {
        dismiss(animated: true, completion: nil)
    }
    
    func rotateButtonTouched(_ button: UIButton) {
        guard let input = currentInput else { return }
        
        let isBackCamera = input == self.backCamera

        if self.switchCamera(isBackCamera) {
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(0.3)
            UIView.setAnimationTransition(isBackCamera ? .flipFromLeft : .flipFromRight, for: button, cache: true)
            UIView.commitAnimations()
        }
    }
    
    func shutterButtonTouched(_ button: ShutterButton) {
        guard let layer = self.cameraView?.previewLayer else { return }
        
        button.isEnabled = false
        UIView.animate(withDuration: 0.1, animations: {
            self.cameraView!.shutterOverlayView.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.cameraView!.shutterOverlayView.alpha = 0
            })
        })
        
        self.takePhoto(layer) { [weak self] buffer in
            button.isEnabled = true
            
            guard
                buffer != nil, let url = self?.imageUrl, let layer = self!.cameraView?.previewLayer,
                let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer!),
                let originalImage = UIImage(data: data)
            else {
                return
            }
            
            let outputRect = layer.metadataOutputRectOfInterest(for: layer.bounds)
            var cgImage = originalImage.cgImage!
            let width = CGFloat(cgImage.width)
            let height = CGFloat(cgImage.height)
            let cropRect = CGRect(x: outputRect.origin.x * width, y: outputRect.origin.y * height, width: outputRect.size.width * width, height: outputRect.size.height * height)
            
            cgImage = cgImage.cropping(to: cropRect)!
//            let croppedImage = UIImageJPEGRepresentation(cgImage.convert(to: originalImage.imageOrientation, size: cropRect.size)
            let croppedImage = UIImage(cgImage: cgImage, scale: Constants.screenScale, orientation: originalImage.imageOrientation)
//            let cropRect = layer.metadataOutputRectOfInterest(for: layer.frame)
//            let cropOrigin = CGPoint(x: cropRect.origin.x * takenImage.size.width, y: cropRect.origin.y * takenImage.size.height)
//            let cropSize = CGSize(width: cropRect.size.width * takenImage.size.width, height: cropRect.size.height * takenImage.size.height)
//            
//            var imageData: Data?
//            var imageSize: CGSize?
//            if let cgImage = takenImage.cgImage {
//                if let result = cgImage.cropping(to: CGRect(origin: cropOrigin, size: cropSize)) {
//                    takenImage = result.convert(to: takenImage.imageOrientation, size: cropSize)
//                    imageData = UIImageJPEGRepresentation(takenImage, 1.0)
//                    imageSize = cropRect.size
//                } else {
//                    imageData = UIImageJPEGRepresentation(cgImage.convert(to: takenImage.imageOrientation, size: takenImage.size), 1.0)
//                }
//            }

            let imageData = UIImageJPEGRepresentation(cgImage.convert(to: originalImage.imageOrientation, size: croppedImage.size), 1.0)
            let editorVC = EditorViewController(imageData ?? data, image: croppedImage, imageKey: self!.imageKey, imageUrl: url)
            editorVC.delegate = self
            editorVC.transitioningDelegate = editorVC
            self!.present(editorVC, animated: true, completion: nil)
        }
    }
}

extension CameraViewController: EditorViewControllerDelegate {
    
    func willCloseEditor() {
        self.view.isHidden = true
    }
    
    func didCloseEditor() {
        self.dismiss(animated: false, completion: nil)
    }
    
}

extension CameraViewController: CameraViewDelegate {
    
    func cameraView(_ cameraView: CameraView, didTouch point: CGPoint) {
        self.setFocus(point)
    }
    
}

extension CameraViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let fromVC = source as? CircleTransitionType {
            return CircleTransition(true, fromView: fromVC.circleView)
        }
        
        return nil
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if (self.cameraView == nil) {
            return nil
        }
        
        return SlideTransition(direction: .right)
    }
    
}

extension CameraViewController: AlertViewControllerDelegate {
    
    func alertAction(_ actionCase: Int) {
        guard let m = AlertAction(rawValue: actionCase) else { return }
        
        switch m {
        case .exitVC:
            self.closeAction()
        case .retrySignin:
            if (self.imageUrl == nil) {
                self.requestSignin()
            }
        }
    }
    
}

//
//  EditorViewController.swift
//  PushBud
//
//  Created by Daria.R on 27/04/17.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import UIKit

protocol EditorViewControllerDelegate {
    func willCloseEditor()
    func didCloseEditor()
}

class EditorViewController: UIViewController {

    fileprivate enum AlertAction: Int {
        case retrySave = 1, retryUpload
    }
    
    var delegate: EditorViewControllerDelegate?
    
    fileprivate var dismissTransition: UIViewControllerAnimatedTransitioning?

    fileprivate var imageUrl: URL?
    private let imageKey: String
    private var imageData: Data?
    private var isUploading = false
    private var isWaitingForUpload = false
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    fileprivate let imageView = UIImageView()
    private let imageOverlayViewTag = 39

    private let txtDescr = UITextView()
    fileprivate let lblDescr = UILabel()
    fileprivate let TITLE_MAX_LENGTH = 120
    
    private var toolBarHeight: CGFloat!
    private let btnSave = UIButton()
    private let btnMap = UIButton()
    private var btnMapHeight: NSLayoutConstraint!
    private let lblPlace = LabelInset()
//    private let lblVisibility = UILabel()
//    private let segVisibility = UISegmentedControl()
    
    fileprivate var isAutoPosition = true

    // Data
    fileprivate var dataLat: Double?
    fileprivate var dataLng: Double?
    fileprivate var dataPlace: String?
    fileprivate var dataAddress: String?
    
    init(_ imageData: Data, image: UIImage, imageKey: String, imageUrl: URL) {
        self.imageKey = imageKey
        
        super.init(nibName: nil, bundle: nil)
        
        self.imageView.image = image
        self.imageData = imageData
        self.imageUrl = imageUrl
        self.uploadImage()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = LocStr("Editor.Title")
        self.setupUI()
        
        // Localization
        self.btnSave.setTitle(LocStr("Save"), for: UIControlState())
        self.lblDescr.text = LocStr("Editor.SlugPlaceholder")
        self.btnMap.setTitle(LocStr("Editor.Location"), for: .normal)
//        self.lblVisibility.text = LocStr("Editor.VisibilityTitle")
//        self.segVisibility.insertSegment(withTitle: LocStr("Private"), at: 0, animated: false)
//        self.segVisibility.insertSegment(withTitle: LocStr("Public"), at: 1, animated: false)
//        self.segVisibility.selectedSegmentIndex = Config.userProfile?.isPrivate == true ? 0 : 1
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Actions
    func keyboardWillShow(_ notification: Notification) {
        guard let value = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }

        var rect = self.contentView.bounds
        rect.size.height -= value.cgRectValue.height
        rect.size.height -= self.toolBarHeight
        
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: value.cgRectValue.height, right: 0)

        self.scrollView.contentInset = insets
        self.scrollView.scrollIndicatorInsets = insets
        
        var txtFrame = self.txtDescr.frame
        if (txtFrame.origin.y + txtFrame.height > rect.height) {
            txtFrame.origin.y += 10
            self.scrollView.scrollRectToVisible(txtFrame, animated: true)
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        self.scrollView.contentInset = .zero
        self.scrollView.scrollIndicatorInsets = .zero
    }
    
    func saveAction() {
        self.saveValues()
    }
    
    func cancelAction() {
        dismiss(animated: true, completion: nil)
    }
    
    func mapAction() {
        let mapVC = EditorMapViewController(lat: self.dataLat, lng: self.dataLng, place: self.dataPlace, address: self.dataAddress, delegate: self)
        self.present(UINavigationController(rootViewController: mapVC), animated: true, completion: nil)
    }
    
    func textViewDone() {
        self.view.endEditing(true)
    }
    
    private func setupImageView(padding: CGFloat) {
        self.imageView.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        self.imageView.clipsToBounds = true
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        Helper.addConstraints(["H:|-0-[Img]-0-|", "V:|-0-[Img]"], source: contentView, views: ["Img" : imageView])

        guard let imageSize = self.imageView.image?.size else { return }

        let availableWidth = Constants.screenSize.width - padding
        let ratio = availableWidth / imageSize.width
        
        contentView.addConstraint(NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: min(availableWidth * 1.4, imageSize.height * ratio)))
    }
    
    fileprivate func uploadImage() {
        guard (!self.isUploading && self.imageUrl != nil) else { return }
        
//        print("https://ik.imagekit.io/mequire/pb/" + self.imageKey)

        self.isUploading = true
        
        let uploader = ImageClient.shared.uploader(self.imageUrl!, imageData: self.imageData!)
        
        uploader.progress = { progress in
            DispatchQueue.main.async {
                LoaderOverlay.shared.progress?.animate(toAngle: Double(progress) * 360.0)
            }
        }
        
        if (self.isWaitingForUpload) {
            LoaderOverlay.shared.showProgress()
        }
        
        self.addProgressOverlay()
        
        uploader.start { [weak self] response in
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("ImageUpload-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            self?.imageUploadDidFinish(with: statusCode, and: response.error)
        }
    }
    
    private func imageUploadDidFinish(with statusCode: Int, and error: NSError?) {
        self.imageView.viewWithTag(imageOverlayViewTag)?.removeFromSuperview()
        self.isUploading = false
        
        if (statusCode == 200) {
            self.imageUrl = nil
            self.imageData = nil
            if (self.isWaitingForUpload) {
                self.saveValues(false)
            }
            return
        }
        
        if (self.isWaitingForUpload) {
            self.isWaitingForUpload = false
            self.view.isUserInteractionEnabled = true
            LoaderOverlay.shared.hideProgress()
        }
        if (error?.isNetworkError == true) {
            Helper.alertNoNetRetry(self, retryCase: AlertAction.retryUpload.rawValue)
        } else {
            UserMessage.shared.show(LocStr("Failure"), body: LocStr("Error.PhotoUploadFailed"))
            error?.record()
        }
    }
    
    func addProgressOverlay() {
        guard (self.imageView.viewWithTag(imageOverlayViewTag) == nil) else { return }
        
        let view = UIView()
        view.tag = self.imageOverlayViewTag
        view.backgroundColor = UIColor(white: 0, alpha: 0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        self.imageView.addSubview(view)
        Helper.addConstraints(["H:|-0-[v]-0-|", "V:|-0-[v]-0-|"], source: self.imageView, views: ["v": view])
        
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        view.addSubview(indicator)
        
        let views: [String : Any] = ["v": view, "i": indicator]
        view.addConstraints(
            NSLayoutConstraint.constraints(withVisualFormat: "V:[v]-(<=1)-[i]", options: .alignAllCenterX, metrics: nil, views: views) +
            NSLayoutConstraint.constraints(withVisualFormat: "H:[v]-(<=1)-[i]", options: .alignAllCenterY, metrics: nil, views: views))
    }
    
    private func saveValues(_ showProgress: Bool = true) {
        guard let slug = self.txtDescr.text.trim() else {
            self.txtDescr.errorShake()
            return
        }
        
        guard let lat = self.dataLat, let lng = self.dataLng else {
            self.btnMap.errorShake()
            return
        }

        self.view.endEditing(true)

        defer {
            self.view.isUserInteractionEnabled = false
        }
        
        guard (self.imageData == nil) else {
            self.isWaitingForUpload = true
            if (self.isUploading) {
                LoaderOverlay.shared.showProgress()
            } else {
                self.uploadImage()
            }
            return
        }
        
        if (showProgress) {
            LoaderOverlay.shared.show()
        }
        
        let data: [String: Any?] = [
            "slug": slug,
            "picture_url": self.imageKey,
            "lat": String(format: "%.7f", lat),
            "lng": String(format: "%.7f", lng),
            "tags": HashTagHelper().find(in: slug)?.joined(separator: ","),
            "place": self.dataPlace,
            "address": self.dataAddress,
            //"is_private": (self.segVisibility.selectedSegmentIndex == 0)
        ]
        print(data)
        
        FeedManager.saveEvent(data) { [weak self] result in
            
            self?.view.isUserInteractionEnabled = true

            switch (result) {
            case .Success(let event):
                self?.didFinish(with: event)
            case .Failure(let error):
                LoaderOverlay.shared.hideProgress()
                
                if (error?.isNetworkError == true), let myself = self {
                    Helper.alertNoNetRetry(myself, retryCase: AlertAction.retrySave.rawValue)
                } else {
                    let message = error?.localizedDescription ?? LocStr("Error.EventCreateFailTip")
                    UserMessage.shared.show(LocStr("Error.EventCreateFailTitle"), body: message)
                    error?.record()
                }
            }
        }
    }
    
    // MARK: - Private
    private func didFinish(with event: Feed) {
        let navVC = (UIApplication.shared.delegate as! AppDelegate).window!.rootViewController as! UINavigationController
        if (navVC.viewControllers.count > 1) {
            navVC.popToRootViewController(animated: false)
        }
        
        if let mapVC = navVC.viewControllers.first as? MapViewController {
            mapVC.didSave(event: event, with: self.imageView.image)
        }
        
        LoaderOverlay.shared.tick() {
            self.delegate?.willCloseEditor()
            self.dismiss(animated: true) {
                self.delegate?.didCloseEditor()
            }
        }
    }
    
    fileprivate func showStaticMap(lat: Double, lng: Double, attributedText: NSAttributedString? = nil) {
        let zoom: Int = self.isAutoPosition ? 11 : 15
        let mapUrl = "https://maps.googleapis.com/maps/api/staticmap?center=\(lat),\(lng)&markers=color:blue%7C\(lat),\(lng)&zoom=\(zoom)&size=\(Int(self.btnMap.frame.width))x200&scale=\(Int(Constants.screenScale))&format=png&maptype=roadmap&key=" + Constants.mapKey
        DispatchQueue.global().async { [unowned self] in
            if let data = try? Data(contentsOf: URL(string: mapUrl)!) {
                DispatchQueue.main.async {
                    self.btnMap.setBackgroundImage(UIImage(data: data), for: .normal)
                    self.btnMap.setTitle(nil, for: .normal)
                    if let text = self.mapLabel {
                        self.lblPlace.attributedText = text
                        self.lblPlace.isHidden = false
                    } else {
                        self.lblPlace.text = nil
                        self.lblPlace.isHidden = true
                    }
                    self.btnMapHeight.constant = 200
                }
            }
        }
    }

    private var mapLabel: NSAttributedString? {
        guard (self.dataPlace != nil || self.dataAddress != nil) else { return nil }

        let attribs: [String: Any] = [NSFontAttributeName: Theme.Font.light.withSize(12)]
        guard (self.dataPlace != nil && self.dataAddress != nil) else {
            return NSAttributedString(string: self.dataPlace ?? self.dataAddress!, attributes: attribs)
        }
        
        let place = self.dataPlace!
        let attrStr = NSMutableAttributedString(string: place + "\n" + self.dataAddress!, attributes: attribs)
        attrStr.addAttribute(NSFontAttributeName, value: Theme.Font.medium.withSize(13), range: NSRange(location: 0, length: place.characters.count))
        return attrStr
    }
    
    private func setupUI() {
        self.btnSave.setTitleColor(Theme.Dark.tint, for: UIControlState())
        self.btnSave.titleLabel?.font = Theme.Font.bold.withSize(18)
        self.btnSave.addTarget(self, action: #selector(saveAction), for: UIControlEvents.touchUpInside)
        self.btnSave.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(btnSave)
        Helper.addConstraints(["H:[Button]-16-|", "V:|-30-[Button(44)]"], source: view, views: ["Button" : btnSave])
        
        //
        let btnClose = UIButton()
        btnClose.tintColor = Theme.Dark.tint
        btnClose.setImage(UIImage(named: "close_big")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
        btnClose.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        btnClose.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(btnClose)
        Helper.addConstraints(["H:|-16-[Button]", "V:|-30-[Button(44)]", "[Button(44)]"], source: view, views: ["Button" : btnClose])
        
        //
        let btnKbDone = UIBarButtonItem(title: LocStr("Keypad.Done"), style: .done, target: self, action: #selector(textViewDone))
        btnKbDone.setTitleTextAttributes([NSFontAttributeName: Theme.Font.medium.withSize(16)], for: .normal)
        
        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.tintColor = Theme.Light.textButtonDarker
        toolBar.isTranslucent = true
        toolBar.isUserInteractionEnabled = true
        toolBar.setItems([UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), btnKbDone], animated: false)
        toolBar.sizeToFit()
        self.toolBarHeight = toolBar.frame.height
        
        let borderColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1).cgColor // 999999
        let borderRadius: CGFloat = 4
        let borderWidth: CGFloat = 1
        let padding: CGFloat = 48.0
        
        //
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(scrollView)
        Helper.addConstraints(["H:|-0-[ScrollView]-0-|", "V:|-80-[ScrollView]-0-|"], source: view, views: ["ScrollView" : scrollView])
        
        //
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        Helper.addConstraints(["H:|-24-[ContentView]-24-|", "V:|-0-[ContentView]-0-|"], source: view, views: ["ContentView" : contentView])
        self.view.addConstraint(NSLayoutConstraint(item: contentView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1.0, constant: -padding))
        
        // Setup ImageView
        self.setupImageView(padding: padding)
        self.imageView.layer.cornerRadius = borderRadius
        self.imageView.layer.borderWidth = borderWidth
        self.imageView.layer.borderColor = borderColor
        
        //
        self.txtDescr.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        self.txtDescr.textColor = UIColor.lightGray
        self.txtDescr.layer.cornerRadius = borderRadius
        self.txtDescr.layer.borderWidth = borderWidth
        self.txtDescr.layer.borderColor = borderColor
        self.txtDescr.inputAccessoryView = toolBar
        self.txtDescr.font = Theme.Font.light.withSize(20)
        self.txtDescr.delegate = self
        self.txtDescr.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(txtDescr)
        Helper.addConstraints(["H:|-0-[Descr]-0-|", "V:[Descr(140)]"], source: contentView, views: ["Descr" : txtDescr])
        contentView.addConstraint(NSLayoutConstraint(item: txtDescr, attribute: .top, relatedBy: .equal, toItem: imageView, attribute: .bottom, multiplier: 1, constant: 32))
        
        //
        self.lblDescr.textColor = UIColor.lightGray
        self.lblDescr.font = Theme.Font.light.withSize(20)
        self.lblDescr.numberOfLines = 0
        self.lblDescr.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(lblDescr)
        contentView.addConstraints([
            NSLayoutConstraint(item: lblDescr, attribute: .leading, relatedBy: .equal, toItem: txtDescr, attribute: .leading, multiplier: 1, constant: 4),
            NSLayoutConstraint(item: lblDescr, attribute: .trailing, relatedBy: .equal, toItem: txtDescr, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: lblDescr, attribute: .top, relatedBy: .equal, toItem: txtDescr, attribute: .top, multiplier: 1, constant: 8)
            ])
        
        //
        let imgArrow = UIImage(named: "arrow_big")!
        self.btnMap.setImage(imgArrow, for: UIControlState())
        self.btnMap.imageEdgeInsets = UIEdgeInsetsMake(0, UIScreen.main.bounds.width - padding - (imgArrow.size.width * 2.0), 0, 0)
        self.btnMap.setTitleColor(UIColor.lightGray, for: UIControlState())
        self.btnMap.addTarget(self, action: #selector(mapAction), for: .touchUpInside)
        self.btnMap.backgroundColor = self.txtDescr.backgroundColor
        self.btnMap.titleLabel?.font = Theme.Font.light.withSize(18)
        self.btnMap.titleLabel?.numberOfLines = 0
        self.btnMap.contentEdgeInsets = UIEdgeInsetsMake(10,0,10,0)
        self.btnMap.imageView?.contentMode = .scaleAspectFit
        self.btnMap.contentHorizontalAlignment = .left
        self.btnMap.layer.masksToBounds = true
        self.btnMap.layer.cornerRadius = borderRadius
        self.btnMap.layer.borderWidth = borderWidth
        self.btnMap.layer.borderColor = borderColor
        self.btnMap.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(btnMap)
        Helper.addConstraints(["H:|-0-[btn]-0-|", "V:[btn]-24-|"], source: contentView, views: ["btn" : btnMap])
        self.btnMapHeight = NSLayoutConstraint(item: btnMap, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 52)
        contentView.addConstraints([NSLayoutConstraint(item: btnMap, attribute: .top, relatedBy: .equal, toItem: txtDescr, attribute: .bottom, multiplier: 1.0, constant: 32), btnMapHeight])
        
//        let visView = UIView()
//        visView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(visView)
//        contentView.addConstraint(NSLayoutConstraint(item: visView, attribute: .top, relatedBy: .equal, toItem: btnMap, attribute: .bottom, multiplier: 1.0, constant: 16.0))
//        Helper.addConstraints(["H:|-0-[View]-0-|", "V:[View(52)]-24-|"], source: contentView, views: ["View": visView])
        
//        self.segVisibility.translatesAutoresizingMaskIntoConstraints = false
//        self.segVisibility.setTitleTextAttributes([NSFontAttributeName: Theme.Font.medium.withSize(12)], for: .normal)
//        self.segVisibility.tintColor = UIColor.lightGray
//        self.segVisibility.translatesAutoresizingMaskIntoConstraints = false
//        visView.addSubview(self.segVisibility)
//        contentView.addConstraints([
//            NSLayoutConstraint(item: visView, attribute: .trailing, relatedBy: .equal, toItem: segVisibility, attribute: .trailing, multiplier: 1.0, constant: 0),
//            NSLayoutConstraint(item: segVisibility, attribute: .top, relatedBy: .equal, toItem: visView, attribute: .top, multiplier: 1.0, constant: 0)
//        ])
        
//        self.lblVisibility.font = Theme.Font.light.withSize(14)
//        self.lblVisibility.textColor = UIColor.lightGray
//        self.lblVisibility.translatesAutoresizingMaskIntoConstraints = false
//        visView.addSubview(self.lblVisibility)
//        visView.addConstraints([
//            NSLayoutConstraint(item: lblVisibility, attribute: .trailing, relatedBy: .equal, toItem: segVisibility, attribute: .leading, multiplier: 1.0, constant: -8.0),
//            NSLayoutConstraint(item: lblVisibility, attribute: .centerY, relatedBy: .equal, toItem: segVisibility, attribute: .centerY, multiplier: 1.0, constant: 0)
//        ])
        
        //
        self.lblPlace.isHidden = true
        self.lblPlace.numberOfLines = 0
        self.lblPlace.backgroundColor = UIColor(white: 0, alpha: 0.8)
        self.lblPlace.textColor = Theme.Dark.tint
        self.lblPlace.font = Theme.Font.light.withSize(14)
        self.lblPlace.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.lblPlace)
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[lbl]-0-|", options: [], metrics: nil, views: ["lbl" : lblPlace]))
        contentView.addConstraint(NSLayoutConstraint(item: lblPlace, attribute: .top, relatedBy: .equal, toItem: btnMap, attribute: .top, multiplier: 1.0, constant: 0))
        
        if let location = LocationManager.shared.lastLocation?.coordinate {
            self.dataLat = location.latitude
            self.dataLng = location.longitude
            self.showStaticMap(lat: location.latitude, lng: location.longitude)
        }
        
    }
}

extension EditorViewController: EditorMapDelegate {
    
    func didFinishWithCoordinate(lat: Double, lng: Double, place: String?, address: String?) {
        self.dataLat = lat
        self.dataLng = lng
        self.dataPlace = place
        self.dataAddress = address
        self.isAutoPosition = false

        self.showStaticMap(lat: lat, lng: lng)
    }
    
}

// MARK:- Text fields delegate methods
extension EditorViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        let newValue = !textView.text.isEmpty
        if (self.lblDescr.isHidden != newValue) {
            self.lblDescr.isHidden = newValue
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }

        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        if (newText.characters.count > TITLE_MAX_LENGTH) {
            textView.text = (newText as NSString).substring(to: TITLE_MAX_LENGTH)
            self.lblDescr.isHidden = true
            return false
        }
        
        return true
    }
}

extension EditorViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let image = self.imageView.image {
            return BlurTransition(isShow: true, image: image)
        }
        
        return SlideTransition(direction: .left)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self.dismissTransition ?? SlideDownTransition(presenting: false)
    }
    
}

extension EditorViewController: AlertViewControllerDelegate {
    
    func alertAction(_ actionCase: Int) {
        guard let m = AlertAction(rawValue: actionCase) else { return }
        
        switch m {
        case .retrySave:
            self.saveAction()
        case .retryUpload:
            self.uploadImage()
        }
    }
    
}

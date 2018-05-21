//
//  TrackingViewController.swift
//  PushBud
//
//  Created by Daria.R on 5/11/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit
import MapKit
import GoogleMaps
import EFCircularSlider

protocol TrackingViewControllerDelegate: class {
    func didSaveTracking(for user: UserExtended)
}

class TrackingViewController: UIViewController {

    fileprivate let mapView: GMSMapView
    fileprivate let mapMarker: GMSMarker
    private let mapHeight: NSLayoutConstraint
    private let mapMinHeight: CGFloat = 0
    private let mapMaxHeight: CGFloat = 250.0

    private let switchRadius = UISwitch()
    private let radiusLabel = UILabel()
    private let slider = EFCircularSlider()
    private let txtDate = UILabel()

    private var expiryLabel: String!
    private var expiryLabelLastAttributes: [String : Any]?
    private let expiryLabelDefaultAttributes: [String : Any] = [
        NSFontAttributeName: Theme.Font.medium.withSize(14),
        NSForegroundColorAttributeName: UIColor(red: 0.588235, green: 0.592157, blue: 0.596078, alpha: 1.0) //969798
    ]
    private var expiryTimer: Timer?

    private var bottomInset: NSLayoutConstraint!

    private var isInitialCoordinate = true
    private let oldTracking = LocationManager.shared.isTracking
    
    weak var delegate: TrackingViewControllerDelegate?
    
    private var trackingId: Int?
    private let user: UserExtended
    private var isTracking = false
    
    private var distance: Float
    private var distanceInMeters: Float {
        return self.distance * 1000
    }
    private var savedDistance: Float?

    // Expiry and Picker
    fileprivate var expiryDate: Date! {
        didSet {
            let fmt = DateFormatter()
            fmt.dateFormat = "MM-dd-yyyy HH:mm"
            self.expiryLabel = fmt.string(from: expiryDate)
            self.onExpiryTimer()
            print(self.expiryDate.timeIntervalSinceNow)
            if (self.expiryTimer == nil && self.expiryDate.timeIntervalSinceNow > 1) {
                self.expiryTimer = Timer.scheduledTimer(timeInterval: 1.1, target: self, selector: #selector(onExpiryTimer), userInfo: nil, repeats: true)
            }
        }
    }
    fileprivate var expiryDates = [Date]()
    fileprivate var components: DateComponents! {
        didSet {
            components.timeZone = TimeZone.current
        }
    }
    fileprivate let pickerContentView = UIView()
    fileprivate let timePickerTag = 49
    fileprivate let dateCollectionView: UICollectionView
    
    private let switchIntersect = UISwitch()

    required init(for user: UserExtended, camera: GMSCameraPosition? = nil) {
        var cam: GMSCameraPosition?
        if (camera == nil) {
            let navVC = (UIApplication.shared.delegate as! AppDelegate).window!.rootViewController as! UINavigationController
            if let mapVC = navVC.viewControllers.first as? MapViewController {
                cam = mapVC.mapCamera
            }
        }
        if (cam == nil) {
            let center = LocationManager.shared.lastLocation?.coordinate ?? LocationManager.defaultCoordinate
            cam = GMSCameraPosition.camera(withTarget: center, zoom: 11)
        }
        
        let map = GMSMapView.map(withFrame: .zero, camera: cam!)
        self.mapHeight = NSLayoutConstraint(item: map, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: self.mapMaxHeight)
        
        self.mapView = map
        self.mapMarker = GMSMarker(position: cam!.target)
        self.mapMarker.map = map
        
        self.user = user
        self.distance = 0.01

        let cvLayout = UICollectionViewFlowLayout()
        cvLayout.scrollDirection = .horizontal
        cvLayout.minimumInteritemSpacing = 10
        cvLayout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        cvLayout.itemSize = CGSize(width: 75, height: 80)
        self.dateCollectionView = UICollectionView(frame: .zero, collectionViewLayout: cvLayout)
        
        super.init(nibName: nil, bundle: nil)
        
        guard let imgMarker = UIImage(named: "marker"), let imgAvatar = UIImage (named: "marker_avatar") else { return }
        
        UIGraphicsBeginImageContextWithOptions(imgMarker.size, false, Constants.screenScale)
        imgMarker.draw(in: CGRect(origin: .zero, size: imgMarker.size))
        imgAvatar.draw(in: CGRect(origin: CGPoint(x: 5, y: 5), size: imgAvatar.size))
        self.mapMarker.icon = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        self.setupDatePickerUI()
        
        if (!self.oldTracking) {
            LocationManager.shared.startTracking()
        }
        
        // TODO: Replace with api data
        self.expiryDate = Date().addingTimeInterval(60 * 60 * 3)
        self.fillDates(from: self.expiryDate, numberOfDays: 7)
        if let timePicker = self.pickerContentView.viewWithTag(timePickerTag) as? UIDatePicker {
            timePicker.setDate(self.expiryDate, animated: false)
        }
        if let index = self.expiryDates.index(of: self.expiryDate) {
            self.dateCollectionView.selectItem(at: IndexPath(item: index, section: 0), animated: true, scrollPosition: .centeredHorizontally)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(cancelAction))

        if (self.isInitialCoordinate) {
            self.changeRadius(distance: self.distance)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (!self.oldTracking) {
            LocationManager.shared.stopTracking()
        }
    }

    // MARK:- Actions
    func cancelAction() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func toggleDatePicker() {
        guard let pickerView = self.pickerContentView.superview else { return }
        
        let newValue = !pickerView.isHidden
        if !newValue {
            pickerView.isHidden = false
        }
        
        UIView.animate(withDuration: 0.33, animations: {
            pickerView.layer.opacity = newValue ? 0 : 1.0
        }) { _ in
            if newValue {
                pickerView.isHidden = true
            }
        }
    }
    
    func onExpiryTimer() {
        let attrStr = NSMutableAttributedString(string: self.expiryLabel + "\n", attributes: self.expiryLabelDefaultAttributes)
        var text: String?
        
        defer {
            attrStr.append(NSAttributedString(string: text ?? CommonStr.TrackingTerm.expired, attributes: self.expiryLabelLastAttributes))
            self.txtDate.attributedText = attrStr
        }
        
        let i = self.expiryDate.timeIntervalSinceNow
        
        guard i > 2 else {
            self.expiryTimer?.invalidate()
            self.expiryTimer = nil
            self.expiryLabelLastAttributes = [NSFontAttributeName: Theme.Font.medium.withSize(14), NSForegroundColorAttributeName: Theme.destructiveTextColor]
            self.txtDate.tag = 0
            return
        }
        
        var tag: Int!
        
        if i < 60 {
            text = String(format: CommonStr.TrackingTerm.seconds, Int(i))
            tag = 1
        } else {
            let days = Int(floor(i / 86400)), hours = Int(floor(i.truncatingRemainder(dividingBy: 86400) / 3600))
            if (0 < days) {
                text = hours > 0 ? String(format: CommonStr.TrackingTerm.dayHours, days, hours) : String(format: CommonStr.TrackingTerm.day, days)
                tag = 2
            } else if 0 < hours {
                text = String(format: CommonStr.TrackingTerm.hours, hours)
                tag = 3
            } else {
                text = String(format: CommonStr.TrackingTerm.minute, Int(i / 60))
                tag = 4
            }
        }

        guard tag != self.txtDate.tag else { return }
        
        self.txtDate.tag = tag
        
        switch (tag) {
        case 1,3:
            self.txtDate.font = Theme.Font.medium.withSize(14)
        default:
            self.txtDate.font = Theme.Font.light.withSize(14)
        }
        
        switch (tag) {
        case 1,4:
            self.txtDate.textColor = Theme.destructiveTextColor
        default:
            self.txtDate.textColor = Theme.Dark.textColor
        }
        
        self.expiryLabelLastAttributes = [NSFontAttributeName: self.txtDate.font, NSForegroundColorAttributeName: self.txtDate.textColor]
    }
    
    func saveAction() {
        LoaderOverlay.shared.show()
        
        let isNotify = self.switchRadius.isOn
        
        /////
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day = 1
        components.month = 3
        components.year = 2018
        self.expiryDate = calendar.date(from: components)
        /////
        
        let expires = Config.apiGmtFormatter.string(from: self.expiryDate)
        let params: [String : Any] = ["user_id": self.user.id, "notify": isNotify, "radis": isNotify ? self.distanceInMeters : 1000,
                                      "expires": expires, "expires_on_intersect": self.switchIntersect.isOn]
        
        HTTP.New(APIClient.baseURL + "tracking", type: .POST, params: params, headers: APIClient.JsonHeaders).start { [weak self] response in
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                DLog("UserTrack::POST-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            guard statusCode == 200 else {
                LoaderOverlay.shared.hide()
                UserMessage.shared.show(LocStr("TRACKING_SAVE_ERROR_TITLE"), body: LocStr("TRACKING_SAVE_ERROR"))
                response.error?.record()
                return
            }
            
            guard let user = self?.user else {
                LoaderOverlay.shared.hide()
                return
            }

            self!.delegate?.didSaveTracking(for: user)
            
            LoaderOverlay.shared.tick {
                self?.cancelAction()
            }

        }
    }
    
    func toggleRadius() {
        let newValue = !self.slider.isHidden
        self.mapHeight.constant = newValue ? self.mapMinHeight : self.mapMaxHeight

        if (newValue) {
            self.slider.isHidden  = true
        }
        
        let alpha: CGFloat = newValue ? 0 : 1.0
        self.radiusLabel.alpha = alpha

        UIView.animate(withDuration: 0.33, animations: {
            self.mapView.layoutIfNeeded()
            self.slider.alpha = alpha
        }) { _ in
            if (newValue) {
                self.slider.alpha = 1.0
            } else {
                self.slider.isHidden = false
            }
        }
    }
    
    func onRadiusAction() {
        let newDistance = self.slider.currentValue
        if (self.distance != newDistance) {
            self.changeRadius(distance: newDistance)
        }
    }

    func timeChanged(_ sender: UIDatePicker) {
        self.expiryDate = sender.date
    }

    // MARK: - Private
    private func fillDates(from date: Date, numberOfDays: Int) {
        let calendar = Calendar.current
        var dates: [Date] = [date]
        var days = DateComponents()
        for i in 1...numberOfDays {
            days.day = i
            if let date = calendar.date(byAdding: days, to: date) {
                dates.append(date)
            }
        }
        
        self.expiryDates = dates
        self.dateCollectionView.reloadData()
    }
    
    private func setupUI() {
        self.navigationItem.titleView = BarTitleView(title: LocStr("Tracking.RequestTitle"), subtitle: self.user.name, textColor: .white)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(cancelAction))
        self.view.backgroundColor = Theme.Light.background
        
        // MapView
        self.mapView.isUserInteractionEnabled = false
        self.mapView.translatesAutoresizingMaskIntoConstraints = false
        self.view.insertSubview(mapView, at: 0)
        Helper.addConstraints(["H:|-0-[m]-0-|", "V:[g]-0-[m]"], source: view, views: ["m": mapView, "g": topLayoutGuide])
        self.mapView.addConstraint(mapHeight)
        
        // Slider
        self.slider.filledColor = Theme.Splash.lightColor
        self.slider.unfilledColor = Theme.Splash.lighterColor.withAlphaComponent(0.7)
        self.slider.handleType = .doubleCircleWithClosedCenter
        self.slider.handleColor = Theme.Splash.darkColor
        self.slider.labelColor = Theme.destructiveTextColor
        self.slider.minimumValue = 1
        self.slider.maximumValue = 100
        self.slider.addTarget(self, action: #selector(onRadiusAction), for: .valueChanged)
        self.slider.snapToLabels = false
        self.slider.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.slider)
        
        let sliderMargin: CGFloat = 12.0
        let doubleMargin = sliderMargin * 2
        self.view.addConstraints([
            NSLayoutConstraint(item: slider, attribute: .top, relatedBy: .equal, toItem: mapView, attribute: .top, multiplier: 1.0, constant: sliderMargin),
            NSLayoutConstraint(item: slider, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: self.mapMaxHeight - doubleMargin),
            NSLayoutConstraint(item: slider, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: self.mapMaxHeight - doubleMargin),
            NSLayoutConstraint(item: slider, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0)])
        
        // PushInRadius Switch
        let lblRadius = UILabel()
        lblRadius.font = Theme.Font.light.withSize(16)
        lblRadius.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(lblRadius)

        switchRadius.setOn(true, animated: false)
        switchRadius.addTarget(self, action: #selector(toggleRadius), for: .valueChanged)
        switchRadius.onTintColor = Theme.Splash.lighterColor
        switchRadius.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(switchRadius)
        
        self.radiusLabel.font = Theme.Font.medium.withSize(12)
        self.radiusLabel.textColor = UIColor(red: 0.5569, green: 0.5569, blue: 0.5765, alpha: 1.0) //8E8E93
        self.radiusLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.radiusLabel)
        
        // PushInRadius Switch
        let dateView = UIView()
        dateView.addTarget(target: self, action: #selector(toggleDatePicker))
        dateView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(dateView)

        // Intersect Expiry
        let lblIntersect = UILabel()
        lblIntersect.font = lblRadius.font
        lblIntersect.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(lblIntersect)
        
        switchIntersect.setOn(false, animated: false)
        switchIntersect.onTintColor = Theme.Splash.lighterColor
        switchIntersect.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(switchIntersect)
        
        // vc.view constraints
        self.view.addConstraints([
            NSLayoutConstraint(item: switchRadius, attribute: .top, relatedBy: .equal, toItem: mapView, attribute: .bottom, multiplier: 1.0, constant: 20.0),
            NSLayoutConstraint(item: view, attribute: .trailingMargin, relatedBy: .equal, toItem: switchRadius, attribute: .trailing, multiplier: 1.0, constant: 0),

            NSLayoutConstraint(item: lblRadius, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leadingMargin, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: lblRadius, attribute: .centerY, relatedBy: .equal, toItem: switchRadius, attribute: .centerY, multiplier: 1.0, constant: 0),
            
            NSLayoutConstraint(item: switchRadius, attribute: .leading, relatedBy: .equal, toItem: radiusLabel, attribute: .trailing, multiplier: 1.0, constant: 8.0),
            NSLayoutConstraint(item: radiusLabel, attribute: .centerY, relatedBy: .equal, toItem: switchRadius, attribute: .centerY, multiplier: 1.0, constant: 0),
            
            NSLayoutConstraint(item: dateView, attribute: .leading, relatedBy: .equal, toItem: lblRadius, attribute: .leading, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: dateView, attribute: .trailing, relatedBy: .equal, toItem: switchRadius, attribute: .trailing, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: dateView, attribute: .top, relatedBy: .equal, toItem: switchRadius, attribute: .bottom, multiplier: 1.0, constant: 20.0),

            NSLayoutConstraint(item: switchIntersect, attribute: .top, relatedBy: .equal, toItem: dateView, attribute: .bottom, multiplier: 1.0, constant: 20.0),
            NSLayoutConstraint(item: switchIntersect, attribute: .trailing, relatedBy: .equal, toItem: switchRadius, attribute: .trailing, multiplier: 1.0, constant: 0),

            NSLayoutConstraint(item: lblIntersect, attribute: .leading, relatedBy: .equal, toItem: lblRadius, attribute: .leading, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: lblIntersect, attribute: .centerY, relatedBy: .equal, toItem: switchIntersect, attribute: .centerY, multiplier: 1.0, constant: 0)])

        let lblDate = UILabel()
        lblDate.font = lblRadius.font
        lblDate.textColor = Theme.Dark.textColor
        lblDate.translatesAutoresizingMaskIntoConstraints = false
        dateView.addSubview(lblDate)

        txtDate.numberOfLines = 0
        txtDate.font = Theme.Font.light.withSize(18)
        txtDate.textAlignment = .right
        txtDate.textColor = Theme.Dark.textColorLighter
        txtDate.translatesAutoresizingMaskIntoConstraints = false
        dateView.addSubview(txtDate)

        let imgArrow = UIImageView(image: UIImage(named: "arrow_big"))
        imgArrow.transform = CGAffineTransform(rotationAngle: 90.toRadians)
        imgArrow.translatesAutoresizingMaskIntoConstraints = false
        dateView.addSubview(imgArrow)
        
        // dateView constraints
        dateView.addConstraints([
            NSLayoutConstraint(item: lblDate, attribute: .leading, relatedBy: .equal, toItem: dateView, attribute: .leading, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: lblDate, attribute: .centerY, relatedBy: .equal, toItem: dateView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: imgArrow, attribute: .centerY, relatedBy: .equal, toItem: dateView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: txtDate, attribute: .top, relatedBy: .equal, toItem: dateView, attribute: .top, multiplier: 1.0, constant: 8.0),
            NSLayoutConstraint(item: dateView, attribute: .trailing, relatedBy: .equal, toItem: imgArrow, attribute: .trailing, multiplier: 1.0, constant: 4.0),
            NSLayoutConstraint(item: dateView, attribute: .trailing, relatedBy: .equal, toItem: txtDate, attribute: .trailing, multiplier: 1.0, constant: 24.0),
            NSLayoutConstraint(item: dateView, attribute: .bottom, relatedBy: .equal, toItem: txtDate, attribute: .bottom, multiplier: 1.0, constant: 8.0)])

        // Save Button
        let btnSave = UIButton()
        btnSave.addTarget(self, action: #selector(saveAction), for: .touchUpInside)
        btnSave.backgroundColor = Theme.Splash.lighterColor
        btnSave.contentEdgeInsets = UIEdgeInsets(top: 10, left: 32, bottom: 12, right: 32)
        btnSave.layer.cornerRadius = 3
        btnSave.setTitleColor(.white, for: .normal)
        if let label = btnSave.titleLabel {
            label.adjustsFontSizeToFitWidth = true
            label.font = Theme.Font.medium.withSize(18)
            label.minimumScaleFactor = 0.5
        }
        btnSave.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(btnSave)
        self.view.addConstraints([
            NSLayoutConstraint(item: btnSave, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: btnSave, attribute: .width, relatedBy: .lessThanOrEqual, toItem: view, attribute: .width, multiplier: 0.8, constant: 0),
            NSLayoutConstraint(item: btnSave, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -12)])
        
        // Localization
        btnSave.setTitle(LocStr(self.isTracking ? "Save" : "Tracking.Request"), for: .normal)
        lblRadius.text = LocStr("Tracking.PushInRadius")
        lblDate.text = LocStr("Tracking.ExpiryTitle")
        lblIntersect.text = LocStr("Tracking.ExpiresOnIntersect")
        
        var labels = [String]()
        for i in 1...10 {
            labels.append(String(format: "%d0km", i))
        }
        self.slider.setInnerMarkingLabels(labels)
    }
    
    private func setupDatePickerUI() {
        let pickerView = UIView()
        pickerView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        pickerView.isHidden = true
        pickerView.layer.opacity = 0
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(pickerView)
        Helper.addConstraints(["H:|-0-[pv]-0-|", "V:[tg]-0-[pv]-0-|"], source: view, views: ["pv": pickerView, "tg": topLayoutGuide])
        
        self.pickerContentView.backgroundColor = .white
        self.pickerContentView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.addSubview(pickerContentView)
        self.bottomInset = NSLayoutConstraint(item: pickerContentView, attribute: .bottom, relatedBy: .equal, toItem: pickerView, attribute: .bottom, multiplier: 1.0, constant: 0)
        pickerView.addConstraint(bottomInset)
        pickerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[ContentView]-0-|", options: [], metrics: nil, views: ["ContentView": pickerContentView]))

        // Top Border
        let topBorder = CALayer()
        topBorder.backgroundColor = Theme.Light.separator
        topBorder.frame = CGRect(x: 0, y: 0, width: Constants.screenSize.width, height: 1.0)
        self.pickerContentView.layer.addSublayer(topBorder)
        
        // UIToolbar
        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.tintColor = Theme.Light.textButtonDarker
        toolBar.isTranslucent = true
        toolBar.isUserInteractionEnabled = true
        toolBar.delegate = self
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        self.pickerContentView.addSubview(toolBar)
        Helper.addConstraints(["H:|-0-[tb]-0-|", "V:|-0-[tb]"], source: pickerContentView, views: ["tb": toolBar])

        let btnDone = UIBarButtonItem(title: LocStr("Keypad.Done"), style: .done, target: self, action: #selector(toggleDatePicker))
        btnDone.setTitleTextAttributes([NSForegroundColorAttributeName: toolBar.tintColor, NSFontAttributeName: Theme.Font.medium.withSize(16)], for: .normal)

        toolBar.setItems([UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), btnDone], animated: false)

        // CollectionView
        self.dateCollectionView.backgroundColor = UIColor(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, alpha: 1)
        self.dateCollectionView.register(TrackingExpiryDateCell.self, forCellWithReuseIdentifier: "dateCell")
        self.dateCollectionView.delegate = self
        self.dateCollectionView.dataSource = self
        self.dateCollectionView.translatesAutoresizingMaskIntoConstraints = false
        self.pickerContentView.addSubview(dateCollectionView)
        
        // Bottom Border
        let bottomBorder = UIView()
        bottomBorder.backgroundColor = UIColor(cgColor: Theme.Light.separator)
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        self.pickerContentView.addSubview(bottomBorder)

        // Time Picker
        let timePicker = UIDatePicker()
        timePicker.tag = self.timePickerTag
        timePicker.addTarget(self, action: #selector(timeChanged(_:)), for: .valueChanged)
        timePicker.clipsToBounds = true
        timePicker.datePickerMode = .time
        timePicker.translatesAutoresizingMaskIntoConstraints = false
        self.pickerContentView.addSubview(timePicker)

        // Constraints
        self.pickerContentView.addConstraints([
            NSLayoutConstraint(item: dateCollectionView, attribute: .top, relatedBy: .equal, toItem: toolBar, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: dateCollectionView, attribute: .leading, relatedBy: .equal, toItem: pickerContentView, attribute: .leading, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: dateCollectionView, attribute: .trailing, relatedBy: .equal, toItem: pickerContentView, attribute: .trailing, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: dateCollectionView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 99.0),
            
            NSLayoutConstraint(item: bottomBorder, attribute: .top, relatedBy: .equal, toItem: dateCollectionView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: bottomBorder, attribute: .leading, relatedBy: .equal, toItem: pickerContentView, attribute: .leading, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: bottomBorder, attribute: .trailing, relatedBy: .equal, toItem: pickerContentView, attribute: .trailing, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: bottomBorder, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 1.0),
            
            NSLayoutConstraint(item: timePicker, attribute: .centerX, relatedBy: .equal, toItem: pickerContentView, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: timePicker, attribute: .top, relatedBy: .equal, toItem: dateCollectionView, attribute: .bottom, multiplier: 1.0, constant: 1.0),
            NSLayoutConstraint(item: pickerContentView, attribute: .bottom, relatedBy: .equal, toItem: timePicker, attribute: .bottom, multiplier: 1.0, constant: 0)
        ])
    }
    
    private func changeRadius(distance: Float) {
        self.distance = distance

        // Mapkit region
        let halfDistance = Double(self.distanceInMeters) / 2
        let region = MKCoordinateRegionMakeWithDistance(self.mapMarker.position, halfDistance, halfDistance)
        
        // Calculate bounds
        let southWest = CLLocationCoordinate2D(
            latitude: region.center.latitude + (region.span.latitudeDelta  / 2),
            longitude: region.center.longitude - (region.span.longitudeDelta / 2)
        )
        let northEast = CLLocationCoordinate2D(
            latitude: region.center.latitude - (region.span.latitudeDelta  / 2),
            longitude: region.center.longitude + (region.span.longitudeDelta / 2)
        )
        let bounds = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)

        // Update bounds
        let update = GMSCameraUpdate.fit(bounds, withPadding: 0)
        self.mapView.moveCamera(update)

        self.radiusLabel.text = String(format: "%d km", Int(distance))

        if (self.isInitialCoordinate) {
            self.isInitialCoordinate = false
            self.slider.currentValue = Float(distance)
        }
    }

}

extension TrackingViewController: LocationManagerDelegate {
    
    func didChangeDirection(_ direction: CLLocationDirection) {}
    
    func didChangeLocationPermission(_ status: PermissionStatus) {}
    
    // MARK: - Location manager delegate
    func didChangeLocation(_ location: CLLocation) {
        LocationManager.shared.delegate = nil
        self.mapMarker.position = location.coordinate
        self.mapView.moveTo(location.coordinate, withZoom: nil)
    }
    
}

extension TrackingViewController: UIToolbarDelegate, UIBarPositioningDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .top
    }
    
}

extension TrackingViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.expiryDates.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dateCell", for: indexPath) as! TrackingExpiryDateCell

        let calendar = Calendar.current
        let oldComps = calendar.dateComponents([.day, .month, .year], from: self.expiryDate)
        let date = self.expiryDates[indexPath.item]
        let newComps = calendar.dateComponents([.day, .month, .year], from: date)

        cell.isSelected = (oldComps.day == newComps.day && oldComps.month == newComps.month && oldComps.year == newComps.year)
        cell.setData(from: date, highlightColor: Theme.Splash.lightColor, darkColor: Theme.Splash.darkColor)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            let offset = CGPoint(x: cell.center.x - collectionView.frame.width / 2, y: 0)
            collectionView.setContentOffset(offset, animated: true)
        }
        
        collectionView.indexPathsForVisibleItems.forEach { sel in
            if sel != indexPath, let cell = collectionView.cellForItem(at: sel), cell.isSelected {
                cell.isSelected = false
            }
        }

        let calendar = Calendar.current
        let dayComponent = calendar.dateComponents([.day, .month, .year], from: self.expiryDates[indexPath.item])

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self.expiryDate)
        components.day = dayComponent.day
        components.month = dayComponent.month
        components.year = dayComponent.year
        
        guard let date = calendar.date(from: components) else { return }
        
        self.expiryDate = date
        (self.pickerContentView.viewWithTag(timePickerTag) as? UIDatePicker)?.setDate(date, animated: false)
    }
    
}


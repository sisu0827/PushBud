//
//  MapViewController.swift
//  PushBud
//
//  Created by Daria.R on 16/04/17.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import UIKit
import GoogleMaps
import UserNotifications

protocol MapDataSource {
    var nearByFeeds: [Feed]? { get }
    func update(_ feed: Feed, at index: Int)
//    func onToggleFollow(userId: Int, newValue: Bool)
}

class MapViewController: UIViewController, CircleTransitionType {
    
    fileprivate enum UserTrackingMode: Int {
        case none, follow, followWithHeading
    }
    
    var circleView: UIView {
        return self.btnCenter.superview ?? self.btnCenter
    }
    
    fileprivate enum AlertAction: Int {
        case logout = 1, locationSettings
    }
    
    var nearByFeeds: [Feed]? {
        return self.items
    }
    
    fileprivate var timer: Timer?
    fileprivate var isFirstLocationUpdate = true
    fileprivate var dialogTimer: Timer?
    fileprivate var notificationTimer : Timer?
    fileprivate var trackingTimer : Timer?
    
//    fileprivate var timedEventsUri: String?
    private var lastFetchedUri: [String : String]?
    
    private var locationAlertShown: Bool?
    
    private var popularTags: [Tag]!
    
    private let emptyViewTag = 9
    private let emptyViewLabel = UILabel()
    private let emptyViewButton = UIButton()

    private var isCameraOn = false {
        didSet {
            self.navigationController?.setNeedsStatusBarAppearanceUpdate()
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    private let leftButtonOriginWhileUserMovingMap = CGPoint(x: -35, y: 10)
    fileprivate var isUserMovingMap: Bool {
        set {
            if (newValue) {
                hideButtons()
            } else {
                showButtons()
            }
        }
        get {
            return self.btnLeft.frame.origin.equalTo(leftButtonOriginWhileUserMovingMap)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return self.isCameraOn
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    fileprivate let categoryCellIdentifier = "CategoryCell"
    fileprivate var lastTrackedLocation: CLLocationCoordinate2D? {
        return self.mapView?.myLocation?.coordinate
    }
    fileprivate var sidebar = Sidebar(frame: CGRect(origin: .zero, size: Constants.screenSize))
    
    private let btnLeft = UIButton(frame: CGRect(x: 20, y: 0, width: 54, height: 55))
    private let btnCenter = UIButton(frame: CGRect(x: 0, y: 10, width: 100, height: 100))
    private var btnRight: [UIButton] = [UIButton(frame: CGRect(x: 0, y: 0, width: 54, height: 55))]
    private var rightViewHeight: NSLayoutConstraint!
    
    private let btnUserTracking = MapToggleTrackingButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    
    fileprivate let defaultPin = UIImage(named: "pin")!
    fileprivate let busyPin = UIImage(named: "pin-grid")!
    private let mapAvatarSize: CGFloat = 48
    private let imagePath = ImageClient.shared.getUrl + ImageClient.scaledUriParam(for: 48)

    fileprivate var ignoreItemUpdates = false
    fileprivate var items: [Feed]? {
        didSet {
            if (!ignoreItemUpdates) {
                self.chunkId += 1
            }
        }
    }
    
    private var chunkId = 0
    
    private var markers: [MapClusterItem]? {
        didSet {
            defer {
                self.clusterManager.cluster()
            }
            
            guard let index = self.markers?.index(where: { $0.imageUrl != nil }) else {
                self.title = ""
                return
            }
            
            self.downloadAvatar(index, url: URL(string: self.imagePath + self.markers![index].imageUrl!)!)
        }
    }
    
    fileprivate var userTrackingMode: UserTrackingMode = .none
    private var clusterManager: GMUClusterManager!
    fileprivate var mapView: GMSMapView?
    private let cachedMarkers = NSCache<AnyObject, AnyObject>()
    
    private func getCachedMarkerPin(_ forKey: AnyObject) -> UIImage? {
        if let data = self.cachedMarkers.object(forKey: forKey) as? Data {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    var mapCamera: GMSCameraPosition? {
        return self.mapView?.camera
    }
    
    private func downloadAvatar(_ index: Int, url: URL) {
        let chunkId = self.chunkId

        let task = ImageClient.shared.session.dataTask(with: url) {
            [weak self] (data: Data?, _: URLResponse?, error: Error?) in
            
            guard self?.chunkId == chunkId, let marker = self!.markers?[index] else { return }

            var image: UIImage?
            if error == nil, let data = data {
                image = UIImage(data: data)?.toCircle()
                if (image != nil) {
                    self!.cachedMarkers.setObject(image! as AnyObject, forKey: "feed-\(marker.placeId)" as AnyObject)
                }
            }
            
            marker.image = image
            marker.imageUrl = nil
            DispatchQueue.main.async {
                self!.markers?[index] = marker
            }
        }
        task.resume()
        self.title = "Downloading \(index + 1) of \(self.items!.count)"
    }
    
    /* private func addMarker(_ item: Feed, image: UIImage?) {
        let location = CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude)
        self.markers?.append(MapClusterItem(location, feedId: item.id, image: image))
    } */
    
    // MARK: - Life Style
    override func viewDidLoad() {
        super.viewDidLoad()

        // Remove self from navigation hierarchy
        if let array = self.navigationController?.viewControllers, array.count > 1 {
            self.navigationController?.navigationItem.leftBarButtonItem = nil
            if let index = array.index(where: { $0 is LoginViewController }) {
                self.navigationController!.viewControllers.remove(at: index)
            }
        }

        // Setup UI
        self.view.backgroundColor = Theme.Light.background
        
        self.emptyViewLabel.numberOfLines = 0
        self.emptyViewLabel.textAlignment = .center
        self.emptyViewLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.btnUserTracking.tintColor = Theme.keypadButtonColor
        self.btnUserTracking.layer.shadowColor = UIColor.darkGray.cgColor
        self.btnUserTracking.layer.shadowOpacity = 0.8
        self.btnUserTracking.layer.shadowRadius = 3
        self.btnUserTracking.layer.shadowOffset = CGSize(width: 0.5, height: 1)
        self.btnUserTracking.layer.cornerRadius = self.btnUserTracking.frame.width / 2
        self.btnUserTracking.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
        self.btnUserTracking.addTarget(self, action: #selector(toggleUserTracking), for: .touchUpInside)
        self.btnUserTracking.translatesAutoresizingMaskIntoConstraints = false
        
        LocationManager.shared.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(enteredForegroundAction), name: .UIApplicationWillEnterForeground, object: nil)

        // Setup Sidebar
        let menuFrame = CGRect(x: -self.sidebar.barWidth, y: 0, width: self.sidebar.barWidth - 1, height: Constants.screenSize.height)
        if let sidebarView: SidebarView = self.sidebar.addSubviewFromNib("SidebarView", iFrame: menuFrame) {
            sidebarView.delegate = self
        }
        
        UIApplication.shared.delegate!.window!!.addSubview(self.sidebar)
        
        self.perform(#selector(registerForNotification), with: nil, afterDelay: 10)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Run notification check when starting, and each 15 minutes.
        self.addNotifsButton()
        notificationTimer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(self.addNotifsButton), userInfo: nil, repeats: true)
        
        trackingTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.get_trackings), userInfo: nil, repeats: true)
        
        if (self.mapView == nil) {
            self.requestLocationServices()
        }
        self.isCameraOn = false
    }
    func addNotifsButton(){
        if let notifController = self.navigationController as? BaseNavigationController {
            print("Running addNotifsButton")
            notifController.addNotifsButton(self.navigationItem, selector: nil, force: true);
        }
    }
    
    func get_trackings(){
        /* Lets get trackings from GET api/trackings/map */
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (self.dialogTimer != nil) {
            self.dialogTimer!.invalidate()
            self.dialogTimer = nil
        }
        if (self.notificationTimer != nil){
            self.notificationTimer?.invalidate()
            self.notificationTimer = nil
        }
    }
    
    // MARK: - Actions
    func registerForNotification() {
        let application = UIApplication.shared
        
        if #available(iOS 10.0, *){
            UNUserNotificationCenter.current().delegate = application.delegate as! AppDelegate
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
        } else {
            let settings : UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        } // End if ios 10
        
        application.registerForRemoteNotifications()
    }
    
    func enteredForegroundAction() {
        if (self.mapView == nil) {
            self.requestLocationServices()
        }
    }
    
    func forceInitMap() {
        self.setupUI()
    }
    
    func addAction() {
        let cameraVC = CameraViewController()
        cameraVC.transitioningDelegate = cameraVC
        self.present(cameraVC, animated: true) { [weak self] in
            self?.isCameraOn = true
        }
    }
    
    func showNotifications(_ sender: UIButton) {
        guard let type = MapBadgeButtonType(rawValue: sender.tag), let navVC = self.navigationController else { return }
        
        let viewController = type == .tracking ? TrackingTableViewController() : FriendsTableViewController()
        navVC.pushViewController(viewController, animated: true)
    }
    
    func updateBadge(_ counter: Int, type: MapBadgeButtonType) {
        guard let btnRight = self.btnRight.last, let view = btnRight.superview else { return }

        let index = self.btnRight.index(where: { $0.tag == type.rawValue })
        let height = Int(btnRight.frame.height) + 8
        
        if counter > 0 {
            guard index == nil else {
                (self.btnRight[index!] as? MapBadgeButton)?.text = "\(counter)"
                return
            }
            
            var size = btnRight.frame.width
            let button = MapBadgeButton(CGRect(x: 0, y: 0, width: size, height: size), type: type)
            button.backgroundColor = .clear
            button.tag = type.rawValue
            button.text = "\(counter)"
            
            size -= 4
            let layer = CALayer()
            layer.frame = CGRect(x: 2, y: 2, width: size, height: size)
            layer.backgroundColor = UIColor.black.withAlphaComponent(0.6).cgColor
            layer.borderWidth = 1
            layer.borderColor = UIColor.white.cgColor
            layer.cornerRadius = size / 2
            button.layer.insertSublayer(layer, at: 0)

            button.addTarget(self, action: #selector(showNotifications(_:)), for: .touchUpInside)
            button.contentEdgeInsets = UIEdgeInsetsMake(12, 12, 12, 12)
            button.tintColor = .white
            button.setImage(UIImage(named: type == .tracking ? "tracking" : "menu_friends")?.withRenderingMode(.alwaysTemplate), for: .normal)
            if let imageLayer = button.imageView?.layer {
                imageLayer.removeFromSuperlayer()
                button.layer.insertSublayer(imageLayer, above: layer)
            }
            view.addSubview(button)
            self.btnRight.insert(button, at: 0)
        } else if let index = self.btnRight.index(where: { $0.tag == type.rawValue }) {
            self.btnRight.remove(at: index).removeFromSuperview()
        } else {
            return
        }

        for (i, button) in self.btnRight.enumerated() {
            button.frame.origin = CGPoint(x: 0, y: i * height)
        }
        
        self.rightViewHeight.constant = CGFloat(height * self.btnRight.count)
    }
    
    func showMenuAction() {
        self.sidebar.toggle(!self.sidebar.isOpen)
    }
    
    func showEventsAction() {
        self.navigationController?.pushViewController(FeedsViewController(dataSource: self, filter: .global, index: nil), animated: true)
    }
    
    func didSave(event: Feed, with image: UIImage?) {
        if (image != nil) {
            if let image = image!.resize(to: CGSize(width: 48 * Int(Constants.screenScale), height: 48 * Int(Constants.screenScale))) {
                self.cachedMarkers.setObject(image.toCircle() as AnyObject, forKey: "feed-\(event.id)" as AnyObject)
            }
            if let data = UIImageJPEGRepresentation(image!, 1.0) {
                ImageClient.shared.setCached(data: data, for: "1080/\(event.pictureUrl)")
            }
        }
        
        self.clusterManager.clearItems()
        if (self.items == nil) {
            self.items  = [event]
        } else {
            self.items!.insert(event, at: 0)
        }
        self.onLoad(flyToMarkerIndex: 0)
    }
    
    func toggleUserTracking() {
        guard LocationManager.permissionStatus() == .authorized else {
            let actions: [AlertActionCase] = [
                AlertActionCase(actionCase: AlertAction.locationSettings.rawValue, title: LocStr("LocationServices.Disabled.Button")),
                AlertActionCase(actionCase: 0, title: LocStr("Cancel"))
            ]
            let alertVC = AlertViewController(LocStr("LocationServices.Unauthorized.Toast.Title"), text: LocStr("Map.UserLocationUnavailableMessage"), actions: actions)
            alertVC.delegate = self
            self.present(alertVC, animated: true)
            return
        }
        
        switch (self.userTrackingMode) {
        case .none:
            self.userTrackingMode = .follow
            self.updateTrackingArrow(rotatedBy: 0)
//            self.mapView?.isMyLocationEnabled = true
        case .follow:
            self.userTrackingMode = .followWithHeading
            LocationManager.shared.setNavigationAccuracy()
            self.btnUserTracking.showFollowingIndicator()
        case .followWithHeading:
            self.userTrackingMode = .none
            self.updateTrackingArrow(rotatedBy: 0.66)
            LocationManager.shared.setNormalAccuracy()
            self.btnUserTracking.hideFollowingIndicator()
//            self.mapView?.isMyLocationEnabled = false
            return
        }
        
        if let coordinate = LocationManager.shared.lastLocation?.coordinate {
            self.mapView?.animate(with: GMSCameraUpdate.setTarget(coordinate))
        }
    }
    
    // MARK: - Private
    private func updateTrackingArrow(rotatedBy: CGFloat) {
        let transform = CGAffineTransform.identity.rotated(by: rotatedBy)
        self.btnUserTracking.arrow?.setAffineTransform(transform)
    }
    
    private func requestLocationServices() {
        let status = LocationManager.permissionStatus()
        switch status {
        case .authorized:
            break;
        case .unknown:
//            if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
//                UserDefaults.standard.set(true, forKey: StorageConstants.isRequestedUpgradeToAlwaysUseLocation)
//                UserDefaults.standard.synchronize()
//            } else {
                self.setupEmptyView("LocationServices.\(status.description)")
                LocationManager.shared.requestAuthorization()
                return
//            }
        case .unauthorized, .disabled:
            self.setupEmptyView("LocationServices.\(status.description)")
            return
        }
    }
    
    fileprivate func locationErrorToast(_ key: String) {
        guard self.locationAlertShown != true else { return }
        
        self.locationAlertShown = true
        
        UserMessage.shared.show(LocStr("\(key).Toast.Title"), body: LocStr("\(key).Toast.Tip"))
    }
    
    func showLocationSettings() {
        Helper.openLocationSettings()
    }
    
    func showAppSettings() {
        Helper.openSettings(url: UIApplicationOpenSettingsURLString)
    }
    
    fileprivate func setupEmptyView(_ key: String) {
        if (self.mapView != nil) {
            self.locationErrorToast(key)
            return
        }
        
        let existingView = self.view.viewWithTag(self.emptyViewTag)
        
        let text = NSMutableAttributedString(string: LocStr("\(key).Title"), attributes: [NSFontAttributeName: Theme.Font.light.withSize(16)]);
        text.append(NSAttributedString(string: "\n\n" + LocStr("\(key).Tip"), attributes: [
            NSFontAttributeName: Theme.Font.light.withSize(14),
            NSForegroundColorAttributeName: Theme.Dark.textColorLighter]))
        self.emptyViewLabel.attributedText = text

        self.emptyViewButton.setTitle(LocStr("\(key).Button"), for: .normal)
        self.emptyViewButton.removeTarget(nil, action: nil, for: .allEvents)
        
        if (key == "LocationServices.Disabled") {
            self.emptyViewButton.addTarget(self, action: #selector(showLocationSettings), for: .touchUpInside)
        } else {
            self.emptyViewButton.addTarget(self, action: #selector(showAppSettings), for: .touchUpInside)
        }
        
        guard (existingView == nil) else { return }
        
        let imageView = UIImageView(image: UIImage(named: "LocationServicesClip"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let emptyView = UIView()
        emptyView.tag = emptyViewTag
        emptyView.addSubview(imageView)
        emptyView.addSubview(emptyViewLabel)
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(emptyView)
        emptyView.addConstraints([
            NSLayoutConstraint(item: imageView, attribute: .top, relatedBy: .equal, toItem: emptyView, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: emptyView, attribute: .centerX, multiplier: 1.0, constant: 0)])
        
        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[lbl]-0-|", options: [], metrics: nil, views: ["lbl": emptyViewLabel])
        constraints.append(NSLayoutConstraint(item: emptyViewLabel, attribute: .top, relatedBy: .equal, toItem: imageView, attribute: .bottom, multiplier: 1.0, constant: 16))
        emptyView.addConstraints(constraints)
        
        self.emptyViewButton.backgroundColor = Theme.Splash.lightColor
        self.emptyViewButton.titleLabel?.font = Theme.Font.light.withSize(16)
        self.emptyViewButton.layer.cornerRadius = 3
        self.emptyViewButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        self.emptyViewButton.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(self.emptyViewButton)
        emptyView.addConstraints([
            NSLayoutConstraint(item: self.emptyViewButton, attribute: .top, relatedBy: .equal, toItem: emptyViewLabel, attribute: .bottom, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: self.emptyViewButton, attribute: .centerX, relatedBy: .equal, toItem: emptyViewLabel, attribute: .centerX, multiplier: 1.0, constant: 0)])
        
        let button = UIButton()
        button.addTarget(self, action: #selector(forceInitMap), for: .touchUpInside)
        button.titleLabel?.font = Theme.Font.light.withSize(14)
        button.setTitleColor(Theme.Light.textButtonDarker, for: .normal)
        button.setTitle(LocStr("Skip"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(button)
        emptyView.addConstraints([
            NSLayoutConstraint(item: button, attribute: .top, relatedBy: .equal, toItem: self.emptyViewButton, attribute: .bottom, multiplier: 1.0, constant: 2),
            NSLayoutConstraint(item: button, attribute: .right, relatedBy: .equal, toItem: self.emptyViewButton, attribute: .right, multiplier: 1.0, constant: 0)])
        
        constraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[EV]-16-|", options: [], metrics: nil, views: ["EV" : emptyView])
        constraints.append(NSLayoutConstraint(item: emptyView, attribute: .bottom, relatedBy: .equal, toItem: button, attribute: .bottom, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint(item: emptyView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0))
        self.view.addConstraints(constraints)
        
        emptyView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            emptyView.alpha = 1
        }
    }
    
    fileprivate func showButtons() {
        let btnLeftOrigin = CGPoint(x: 20, y: 0)
        guard !self.btnLeft.frame.origin.equalTo(btnLeftOrigin) else { return }
        
        let height = Int(self.btnLeft.frame.height)
        let padding = 8

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 2.6, options: UIViewAnimationOptions(), animations: {
            self.btnLeft.frame.origin = btnLeftOrigin
            self.btnCenter.frame.origin = CGPoint(x: 0, y: 10)
            for (i, btn) in self.btnRight.enumerated() {
                btn.frame.origin = CGPoint(x: 0, y: (height + padding) * i)
            }
        }, completion: nil)
    }
    
    fileprivate func hideButtons() {
        guard !self.isUserMovingMap else { return }
        
        if self.userTrackingMode != .none {
            self.userTrackingMode = .none
            self.updateTrackingArrow(rotatedBy: 0.66)
            LocationManager.shared.setNormalAccuracy()
            self.btnUserTracking.hideFollowingIndicator()
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 2.6, options: UIViewAnimationOptions(), animations: {
            self.btnLeft.frame.origin = self.leftButtonOriginWhileUserMovingMap
            self.btnCenter.frame.origin = CGPoint(x: 0, y: 100)
            for (i,btn) in self.btnRight.enumerated() {
                btn.frame.origin = CGPoint(x: 55, y: (i * 62) + 10)
            }
        }, completion: nil)
    }
    
    fileprivate func setupUI(with coordinate: CLLocationCoordinate2D? = nil) {
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 70, height: self.btnLeft.frame.height + 7.0))
        let centerView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 130))
        let rightView = UIView(frame: CGRect(x: 0, y: 0, width: 70, height: self.btnRight.first!.frame.height + 7.0))
        self.view.addSubviews([leftView, centerView, rightView])
        Helper.addConstraints([
            "H:|-0-[lv]","V:[lv(\(Int(leftView.frame.height)))]-0-|","[lv(\(Int(leftView.frame.width)))]",
            "V:[cv(\(Int(centerView.frame.height)))]-0-|","[cv(\(Int(centerView.frame.width)))]",
            "H:[rv]-0-|","V:[rv]-0-|","[rv(\(Int(rightView.frame.width)))]",
        ], source: view, views: ["lv": leftView, "cv": centerView, "rv": rightView])
        self.view.addConstraint(NSLayoutConstraint(item: centerView, attribute: .centerX, relatedBy: .equal, toItem: view,
                                                   attribute: .centerX, multiplier: 1.0, constant: 0))
        self.rightViewHeight = rightView.heightAnchor.constraint(equalToConstant: rightView.frame.height)
        self.rightViewHeight.isActive = true
        
        ([self.btnLeft, self.btnCenter]+self.btnRight).forEach { btn in
            btn.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            btn.layer.cornerRadius = btn.frame.size.width / 2
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.white.cgColor
        }
        
        self.btnLeft.addTarget(self, action: #selector(showEventsAction), for: .touchUpInside)
        self.btnLeft.contentEdgeInsets = UIEdgeInsetsMake(15.0, 15.0, 15.0, 15.0)
        self.btnLeft.setImage(UIImage(named: "List"), for: .normal)
        leftView.addSubview(btnLeft)
        
        self.btnCenter.addTarget(self, action: #selector(addAction), for: .touchUpInside)
        self.btnCenter.setImage(UIImage(named: "map_camera"), for: .normal)
        self.btnCenter.tintColor = .white
        centerView.addSubview(btnCenter)
        
        if let button = self.btnRight.first {
            button.addTarget(self, action: #selector(showMenuAction), for: .touchUpInside)
            button.contentEdgeInsets = UIEdgeInsetsMake(15.0, 15.0, 15.0, 15.0)
            button.setImage(UIImage(named: "Menu"), for: .normal)
            rightView.addSubview(button)
        }
        
        self.view.viewWithTag(self.emptyViewTag)?.removeFromSuperview()

        guard self.mapView == nil else { return }
        
        let coord = coordinate ?? LocationManager.lastUserCoordinate
        var zoomLevel: Float?
        
        if let values = UserStorage.shared.lastUserLocation?.components(separatedBy: "|"), values.count > 2 {
            zoomLevel = Float(values[2])
        }
        
        let camera = GMSCameraPosition.camera(withTarget: coord ?? LocationManager.defaultCoordinate, zoom: zoomLevel ?? 11)
        let map = GMSMapView.map(withFrame: .zero, camera: camera)
        map.translatesAutoresizingMaskIntoConstraints = false
        self.view.insertSubview(map, at: 0)
        Helper.addConstraints(["H:|-0-[Map]-0-|", "V:[TlG]-0-[Map]-0-|"], source: view, views: ["Map" : map, "TlG" : topLayoutGuide])
        map.delegate = self

        let iconGenerator = GMUDefaultClusterIconGenerator()
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = GMUDefaultClusterRenderer(mapView: map, clusterIconGenerator: iconGenerator)
        renderer.delegate = self
        clusterManager = GMUClusterManager(map: map, algorithm: algorithm, renderer: renderer)
        clusterManager.setDelegate(self, mapDelegate: self)
        self.mapView = map
        
        self.view.addSubview(btnUserTracking)
        let btnSize = "[B(\(Int(self.btnUserTracking.frame.width)))]"
        Helper.addConstraints(["H:[B]-8-|", "V:[G]-8-" + btnSize, btnSize], source: view, views: ["B":btnUserTracking,"G":topLayoutGuide])
        
        LocationManager.shared.startTracking()
        if let notifController = self.navigationController as? BaseNavigationController {
            notifController.addNotifsButton(self.navigationItem, selector: nil, force: true)
        }
    }
    
    fileprivate func loadEvents() {
        guard let positon = self.mapView?.camera.target else { return }
//        print(positon)
//        print("sdf")
        
        let params = GMSCoordinateBounds(region: self.mapView!.projection.visibleRegion()).toParams
        
//        print(params)
        
        if let lastParams = self.lastFetchedUri, params == lastParams {
            return
        }
        
        APIClient.Headers["x-pb-position"] = String(format: "%.7f", positon.latitude) + "," + String(format: "%.7f", positon.longitude)
        
        FeedManager.get(params: params) { [weak self] result in
            
            switch result {
            case .Success(let items):
                guard let myself = self else { return }
                myself.lastFetchedUri = params
                myself.clusterManager.clearItems()
                myself.items = items?.1
                if (items == nil) {
                    myself.showEmptyDialogIfNecessary()
                } else {
                    myself.onLoad()
                }
            case .Failure(let error):
                // TODO: show some kind of error message, but this can be fired very often
                DLog("Cannot get events: \(error?.localizedDescription ?? "")", level: .error)
            }
        }
    }

    private func onLoad(flyToMarkerIndex: Int? = nil) {
        guard let items = self.items else { return }
        
        let markers: [MapClusterItem] = items.map { item in
            let location = CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude)
            let image = self.cachedMarkers.object(forKey: "feed-\(item.id)" as AnyObject) as? UIImage
            return MapClusterItem(location, feedId: item.id, image: image, imageUrl: image == nil ? item.pictureUrl : nil)
        }
        self.clusterManager.add(markers)
        self.markers = markers
        
        guard let index = flyToMarkerIndex else { return }
        
        let item = items[index]
        let position = CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude)
        self.mapView?.moveTo(position)
    }
    
    func showEmptyDialog() {
        self.dialogTimer = nil
        
        guard (self.items == nil) else { return }
        guard self.popularTags != nil else {
            self.loadPopularTags()
            return
        }
        
        let viewController = DialogViewController(LocStr("Map.EmptyTip"), hideStorageKey: StorageConstants.keyHidePopularTagsDialog)
        
        guard let view: PopularTagView = viewController.addDetailViewFromNib("PopularTagView") else { return }
        
        view.button.setTitle(LocStr("Cancel").uppercased(), for: .normal)
        view.button.addTarget(viewController, action: #selector(DialogViewController.hideFiveMinuteAction), for: .touchUpInside)
        
        view.delegate = self

        let button = view.setup(with: self.popularTags)
        button.setTitle(LocStr("Dialog.MayBeTomorrow").uppercased(), for: .normal)
        button.addTarget(viewController, action: #selector(DialogViewController.hideOneDayAction), for: .touchUpInside)
        self.present(viewController, animated: true)
    }
    
    fileprivate func showEmptyDialogIfNecessary() {
        guard UserStorage.shared.isPopularTagsDialogAvailable else { return }
        
        if (self.dialogTimer != nil) {
            self.dialogTimer!.invalidate()
        }
        
        self.dialogTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(showEmptyDialog), userInfo: nil, repeats: false)
        
        if (self.popularTags == nil) {
            self.loadPopularTags()
        }
    }
    
    private func loadPopularTags() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        TagManager.getPopularTags(withLimit: 8) { [weak self] result in

            UIApplication.shared.isNetworkActivityIndicatorVisible = false

            switch result {
            case .Success(let tags):
                self?.popularTags = tags
            case .Failure:
                break;
            }

        }
    }
    
}

extension MapViewController: SidebarDelegate {
    
    func didTapSidebar(item: SidebarAction) {
        self.sidebar.toggle(false)
        switch item {
        case .friends:
            self.navigationController?.pushViewController(FriendsTableViewController(), animated: true)
        case .tags:
            self.navigationController?.pushViewController(TagsTableViewController(), animated: true)
        case .feeds:
            self.navigationController?.pushViewController(FeedsViewController(dataSource: self, filter: .own, index: nil), animated: true)
        case .logout:
            let viewController = AlertViewController(LocStr("Logout"), text: LocStr("Sidebar.LogoutAlert"), actions: [
                AlertActionCase(actionCase: AlertAction.logout.rawValue, title: "OK"),
                AlertActionCase(actionCase: 0, title: LocStr("Cancel"))
                ])
            viewController.delegate = self
            self.present(viewController, animated: true)
        case .account:
            let accountVC = AccountViewController()
            accountVC.profile = Config.userProfile
            self.navigationController?.pushViewController(accountVC, animated: true)
        case .changePassword:
            let viewController = ChangePasswordViewController()
            self.navigationController?.pushViewController(viewController, animated: true)
        case .settings,.count:
            break;
        }
    }

}

// MARK: - LocationManagerDelegate
extension MapViewController: LocationManagerDelegate {
    
    func didChangeLocation(_ location: CLLocation) {
        if (self.mapView == nil) {
            self.setupUI(with: location.coordinate)
            self.mapView!.isMyLocationEnabled = true
        } else if (self.userTrackingMode != .none) {
            self.mapView?.animate(with: GMSCameraUpdate.setTarget(location.coordinate))
        } else if (self.isFirstLocationUpdate) {
            self.mapView?.moveCamera(GMSCameraUpdate.setTarget(location.coordinate))
            self.isFirstLocationUpdate = false
        }
    }
    
    func didChangeDirection(_ direction: CLLocationDirection) {
        self.mapView?.animate(toBearing: direction)
    }
    
    func didChangeLocationPermission(_ status: PermissionStatus) {
        guard status == .authorized else {
            if (self.mapView == nil) {
                self.setupEmptyView("LocationServices.\(status.description)")
            } else {
                self.mapView!.isMyLocationEnabled = false
            }
            return
        }

        if (self.mapView == nil) {
            self.setupUI()
        }
        self.mapView!.isMyLocationEnabled = true
    }
    
}

extension MapViewController: MapDataSource {
    
    func update(_ feed: Feed, at index: Int) {
        self.ignoreItemUpdates = true
        self.items?[index] = feed
        self.ignoreItemUpdates = false
    }
    
    /* func onToggleFollow(userId: Int, newValue: Bool) {
        guard self.items != nil else { return }

        self.ignoreItemUpdates = true
        
        for (i,f) in self.items!.enumerated() {
            if (f.user.id == userId) {
                self.items![i].isFriend = newValue
            }
        }
        
        self.ignoreItemUpdates = false
    } */
    
}

extension MapViewController: AlertViewControllerDelegate {
    
    func alertAction(_ actionCase: Int) {
        guard let action = AlertAction(rawValue: actionCase) else { return }
        
        switch (action) {
        case .logout:
            self.logOut()
        case .locationSettings:
            Helper.openLocationSettings()
        }
    }

    private func logOut() {
        guard let window = UIApplication.shared.keyWindow else { return }
        
        let rootVC = LoginViewController()
        let snapshot = window.snapshotView(afterScreenUpdates: true)
        rootVC.view.addSubview(snapshot!)
        window.rootViewController = CommonNavigationController(rootViewController: rootVC)
        
        UIView.animate(withDuration: 0.3, animations: {() in
            snapshot!.layer.opacity = 0
            snapshot!.layer.transform = CATransform3DMakeScale(1.5, 1.5, 1.5)
        }, completion: { _ in
            snapshot!.removeFromSuperview()
        })

        self.sidebar.removeFromSuperview()

        UserManager.logout()
    }
}

extension MapViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        self.isUserMovingMap = gesture
    }
    
    func mapView(_ mapView: GMSMapView, idleAt cameraPosition: GMSCameraPosition) {
        self.isUserMovingMap = false

        if (self.timer != nil) {
            self.timer!.invalidate()
        }
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(loadEventsTimed), userInfo: nil, repeats: false)
        if (self.items == nil) {
            self.showEmptyDialogIfNecessary()
        }
    }
    
    func loadEventsTimed() {
        self.timer = nil
        self.loadEvents()
    }
}

extension MapViewController: GMUClusterManagerDelegate, GMUClusterRendererDelegate {
    
    func renderer(_ renderer: GMUClusterRenderer, willRenderMarker marker: GMSMarker) {
        if let m = marker.userData as? MapClusterItem {
            if let image = m.image {
                marker.icon = image
            } else {
                marker.icon = m.imageUrl == nil ? self.defaultPin : self.busyPin
            }
        }
    }
    
    func clusterManager(_ clusterManager: GMUClusterManager, didTap clusterItem: GMUClusterItem) -> Bool {
        let feedId = clusterItem.placeId
        if let index = self.items!.index(where: { $0.id == feedId }) {
            self.navigationController?.pushViewController(FeedsViewController(dataSource: self, filter: .map, index: index), animated: true)
        }

        return true
    }
    
    func clusterManager(_ clusterManager: GMUClusterManager, didTap cluster: GMUCluster) -> Bool {
        let newCamera = GMSCameraPosition.camera(withTarget: cluster.position, zoom: mapView!.camera.zoom + 1)
        self.mapView!.moveCamera(GMSCameraUpdate.setCamera(newCamera))
        return true
    }
}

extension MapViewController: PopularTagDelegate {
    
    func didTap(popularTag tag: Tag) {
        self.dismiss(animated: true) { [weak self] in
            guard let myself = self else { return }
            
            let viewController = FeedsViewController(dataSource: myself, filter: .global, index: nil, filterTag: tag)
            myself.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
}

extension GMSCoordinateBounds {
    var toParams: [String : String] {
        return [
            "n": String(format: "%.7f", northEast.latitude),
            "e": String(format: "%.7f", northEast.longitude),
            "s": String(format: "%.7f", southWest.latitude),
            "w": String(format: "%.7f", southWest.longitude)
        ]
    }
}

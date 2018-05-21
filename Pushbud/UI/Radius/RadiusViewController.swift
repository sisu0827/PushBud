//
//  RadiusViewController.swift
//  PushBud
//
//  Created by Daria.R on 14/08/16.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import UIKit
import MapKit
import GoogleMaps
import EFCircularSlider

protocol RadiusViewControllerDelegate: class {
    func radiusDidChange(radius: Float, for friendId: Int?)
}

class RadiusViewController: UIViewController {

    private let mapView: GMSMapView

    private let slider = EFCircularSlider()
    private var isInitialCoordinate = true
    private let oldTracking = LocationManager.shared.isTracking
    
    weak var delegate: RadiusViewControllerDelegate?
    
    private let friendId: Int?
    private var distance: Float
    private var distanceInMeters: Float {
        return self.distance * 1000
    }
    private var savedDistance: Float?

    required init(distance: Float?, for friendId: Int? = nil, camera: GMSCameraPosition? = nil) {
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
        
        self.mapView = GMSMapView.map(withFrame: .zero, camera: cam!)
        self.friendId = friendId
        self.savedDistance = distance
        self.distance = distance ?? 0.01

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()

        if (self.oldTracking) {
            LocationManager.shared.stopTracking()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: LocStr("Friendship.StopNotification"), style: .plain, target: self, action: #selector(disableAction))
        
        if (!self.isInitialCoordinate) {
            return
        }

        self.changeRadius(distance: self.distance)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (self.oldTracking) {
            LocationManager.shared.startTracking()
        }
    }

    // MARK:- Actions
    func cancelAction() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func disableAction() {
        let viewController = AlertViewController("TODO", text: "DISABLE NOTIFICATION", actions: [AlertActionCase(actionCase: 0, title: "OK")])
        self.present(viewController, animated: true)
    }
    
    func saveAction() {
        LoaderOverlay.shared.show()

        let radius = Int(self.distanceInMeters)
        var params: [String : Any] = ["radius": radius]
        if let id = self.friendId {
            params["user_id"] = id
        }
        
        HTTP.New(APIClient.baseURL + "radius", type: .PUT, params: params, headers: APIClient.JsonHeaders).start { [weak self] response in
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                DLog("Radius::PUT-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            guard statusCode == 200 else {
                LoaderOverlay.shared.hide()
                UserMessage.shared.show(LocStr("CHANGE_RADIUS_ERROR_TITLE"), body: LocStr("CHANGE_RADIUS_ERROR"))
                response.error?.record()
                return
            }
            
            guard let strongSelf = self else {
                LoaderOverlay.shared.hide()
                return
            }

            strongSelf.delegate?.radiusDidChange(radius: Float(radius), for: strongSelf.friendId)
            
            LoaderOverlay.shared.tick {
                strongSelf.cancelAction()
            }

        }
    }
    
    func onRadiusAction() {
        let newDistance = self.slider.currentValue
        if (self.distance != newDistance) {
            self.changeRadius(distance: newDistance)
        }
    }

    // MARK: - Private
    private func setupUI() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(cancelAction))

        // Slider
        let size = self.view.frame.size
        self.slider.frame = CGRect(x: 10, y: (size.height / 2) - ((size.width / 2) - 40), width: size.width - 20, height: size.width - 20)
//        self.slider.filledColor = FlatGreen()
//        self.slider.unfilledColor = FlatTealDark()
        self.slider.handleType = .doubleCircleWithClosedCenter
//        self.slider.labelColor = FlatGreen()
        self.slider.minimumValue = 1
        self.slider.maximumValue = 100
        self.slider.addTarget(self, action: #selector(onRadiusAction), for: .valueChanged)
        self.slider.snapToLabels = false
        self.view.addSubview(self.slider)
        
        // MapView
        self.mapView.isUserInteractionEnabled = false
        self.mapView.translatesAutoresizingMaskIntoConstraints = false
        self.view.insertSubview(mapView, at: 0)
        Helper.addConstraints(["H:|-0-[m]-0-|", "V:[g]-0-[m]-0-|"], source: view, views: ["m": mapView, "g": topLayoutGuide])
        
        // Save Button
        let btnSave = UIButton()
        btnSave.addTarget(self, action: #selector(saveAction), for: .touchUpInside)
        btnSave.backgroundColor = Theme.Splash.lighterColor
        btnSave.contentEdgeInsets = UIEdgeInsets(top: 10, left: 50, bottom: 12, right: 50)
        btnSave.layer.cornerRadius = 3
        btnSave.setTitleColor(.white, for: .normal)
        btnSave.titleLabel?.font = Theme.Font.medium.withSize(18)
        btnSave.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(btnSave)
        self.view.addConstraints([
            NSLayoutConstraint(item: btnSave, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: btnSave, attribute: .width, relatedBy: .lessThanOrEqual, toItem: view, attribute: .width, multiplier: 0.66, constant: 0),
            NSLayoutConstraint(item: btnSave, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -12)])
        
        // Localization
        btnSave.setTitle(LocStr("Save"), for: .normal)
        
        var labels = [String]()
        for i in 1...10 {
            labels.append(String(format: "%d0km", i))
        }
        self.slider.setInnerMarkingLabels(labels)
    }
    
    private func changeRadius(distance: Float) {
        self.distance = distance

        // Mapkit region
        let halfDistance = Double(self.distanceInMeters) / 2
        let region = MKCoordinateRegionMakeWithDistance(self.mapView.camera.target, halfDistance, halfDistance)
        
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

        self.title = String(format: "%d km", Int(distance))
        if (self.isInitialCoordinate) {
            self.isInitialCoordinate = false
            self.slider.currentValue = Float(distance)
        }
    }

}

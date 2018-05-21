//
//  LocationManager.swift
//  PushBud
//
//  Created by Daria.R on 4/13/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit
import CoreLocation

protocol LocationManagerDelegate {
    func didChangeLocation(_ location: CLLocation)
    func didChangeDirection(_ direction: CLLocationDirection)
    func didChangeLocationPermission(_ status: PermissionStatus)
}

enum PermissionStatus: Int, CustomStringConvertible {
    case authorized, unauthorized, unknown, disabled
    
    var description: String {
        switch self {
        case .authorized:
            return "Authorized"
        case .unauthorized:
            return "Unauthorized"
        case .unknown:
            return "Unknown"
        case .disabled:
            return "Disabled"
        }
    }
}

class LocationManager: NSObject {

    class var shared: LocationManager {
        struct Static {
            static let instance = LocationManager()
        }
        return Static.instance
    }

    var delegate: LocationManagerDelegate?
    
    var lastLocation : CLLocation? {
        didSet {
            self.reportQueue.async { [weak self] in
                self?.report()
            }
        }
    }
    
    fileprivate let isLoggingEnabled = false
    fileprivate let manager = CLLocationManager()
    
    // Location Reporting Props
    private let reportQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.utility)
    private let reportIntervalActive = -15.0
    private let reportIntervalBackground = -300.0
    fileprivate var lastReportedLocation : CLLocation?
    fileprivate var lastReportedLocationDate : Date?
    fileprivate let distanceReportTreshold = 5.0
    fileprivate var isReporting = false

    var isTracking: Bool {
        return self.delegate != nil
    }
    
    // Mark: - Static
    static var lastUserCoordinate: CLLocationCoordinate2D? {
        guard
            let values = UserStorage.shared.lastUserLocation?.components(separatedBy: "|"),
            values.count > 1, let lat = Double(values[0]), let lng = Double(values[1])
        else {
            return nil
        }
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    static var defaultCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: 49.903, longitude: 13.887)
    }
    
    static func permissionStatus(authorizationStatus: CLAuthorizationStatus? = nil) -> PermissionStatus {
        guard CLLocationManager.locationServicesEnabled() else { return .disabled }
        
        switch (authorizationStatus ?? CLLocationManager.authorizationStatus()) {
        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized
        case .restricted, .denied:
            return .unauthorized
//        case .authorizedWhenInUse:
//            if UserDefaults.standard.bool(forKey: StorageConstants.isRequestedUpgradeToAlwaysUseLocation) {
//                return .unauthorized
//            } else {
//                return .unknown
//            }
        case .notDetermined:
            return .unknown
        }
    }
    
    // Mark: - Life Style
    private override init() {
        super.init()

        manager.allowsBackgroundLocationUpdates = true  //Erik
//        if #available(iOS 9.0, *){
//            manager.allowsBackgroundLocationUpdates = true
//        }

        manager.pausesLocationUpdatesAutomatically = false    //Erik
        self.setNormalAccuracy()  //Erik
        manager.distanceFilter = kCLDistanceFilterNone
        manager.headingFilter = 2
        manager.delegate = self
    }
    
    
    // Mark: - Actions
    func setNormalAccuracy() {
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func setNavigationAccuracy() {
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    }
    
    func startTracking() {
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }
    
    func requestAuthorization() {
        manager.requestAlwaysAuthorization()
//        manager.requestWhenInUseAuthorization()
    }
    
    func stopTracking() {
        self.delegate = nil
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    // MARK: - Private
    private func report() {
        print("REPORT function is called@!!!")
        guard !self.isReporting, let loc = self.lastLocation else { return }
        
        let interval = UIApplication.shared.applicationState == .active ? reportIntervalActive : reportIntervalBackground
        let now = self.lastReportedLocationDate?.timeIntervalSinceNow
        if now != nil, interval < now!, let dist = self.lastReportedLocation?.distance(from: loc), dist <= distanceReportTreshold {
            return // either distance or reporting too close
        }//Erik
        
        self.isReporting = true
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let params: [String : Any] = [
            "lat": loc.coordinate.latitude,
            "lng": loc.coordinate.longitude,
            "speed": max(loc.speed, 0)
        ]
        
       
        HTTP.New(APIClient.baseURL + "position", type: .POST, params: params, headers: APIClient.JsonHeaders).start { response in
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            print("API/POSITION API called!!!")
            
            if (self.isLoggingEnabled) {
                print("Location::Report-HTTP\(response.statusCode ?? 0)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            self.isReporting = false
            
            guard (response.statusCode == 200) else { return }
            
            self.lastReportedLocationDate = Date()
            self.lastReportedLocation = loc
        }
        
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let permissionStatus = LocationManager.permissionStatus(authorizationStatus: status)
        delegate?.didChangeLocationPermission(permissionStatus)
        DLog("Location manager did change authorization status to: \(status)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if self.isLoggingEnabled {
            DLog("Location manager received \(locations.count) locations")
        }
        
        var location: CLLocation?
        if (locations.count > 1) {
            location = locations.sorted(by: { $0.timestamp < $1.timestamp }).last
        } else {
            location = locations.last
        }
        
        guard (location != nil) else { return }
        
        if self.isLoggingEnabled {
            DLog("Location \(location!.coordinate) will be used")
        }
        
        self.lastLocation = location
        self.delegate?.didChangeLocation(lastLocation!)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if (newHeading.headingAccuracy > 0 && manager.desiredAccuracy == kCLLocationAccuracyBestForNavigation) {
            self.delegate?.didChangeDirection(newHeading.magneticHeading)
        }
    }
    
}

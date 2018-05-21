//
//  EditorMapViewController.swift
//  PushBud
//
//  Created by Daria.R on 28/04/17.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

protocol EditorMapDelegate {
    func didFinishWithCoordinate(lat: Double, lng: Double, place: String?, address: String?)
}

class EditorMapViewController: UIViewController {

    struct Place {
        let name: String
        let address: String?
        let coordinate: CLLocationCoordinate2D
        let distance: Int
    }
    
    private var delegate: EditorMapDelegate?
    
    fileprivate let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 0))
    fileprivate var searchTimer: Timer?
    fileprivate var lastSearch = ""
    fileprivate var isSearching = false {
        didSet {
            self.lblPlace.isHidden = isSearching
            UIView.animate(withDuration: 0.4) {
                self.overlayView.frame.origin.y = self.isSearching ? 0 : -self.view.frame.height
                self.overlayView.layer.opacity = self.isSearching ? 1 : 0
            }
            if (isSearching) {
                let coord = self.mapView.camera.target
                self.centerCoord = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                self.mapBounds = mapView.projection.visibleRegion()
            }
        }
    }
    fileprivate var places: [Place]? {
        didSet {
            if (1 < self.places?.count ?? 0) {
                self.places!.sort(by: {
                    $0.distance < $1.distance
                })
            }
            self.tableView.reloadData()
        }
    }
    fileprivate let marker: GMSMarker
    fileprivate let mapView = GMSMapView()
    fileprivate let placesClient = GMSPlacesClient.shared()
    private var centerCoord: CLLocation!
    private var mapBounds: GMSVisibleRegion!

    private let overlayView = UIView()
    fileprivate let tableView = UITableView()

    fileprivate let lblPlace = LabelInset()
    private var placeName: String?
    private var placeAddress: String?
    
    init(lat: Double?, lng: Double?, place: String? , address: String?, delegate: EditorMapDelegate) {
        
        let location: CLLocationCoordinate2D
        if (lat == nil || lng == nil) {
            location = LocationManager.shared.lastLocation?.coordinate ?? LocationManager.defaultCoordinate
        } else {
            location = CLLocationCoordinate2D(latitude: lat!, longitude: lng!)
        }
        
        self.marker = GMSMarker(position: location)

        super.init(nibName: nil, bundle: nil)

        if (place == nil) {
            self.lblPlace.text = nil
        } else {
            self.updatePlace(name: place!, address: address)
        }
        
        self.mapView.camera = GMSCameraPosition.camera(withTarget: location, zoom: 11)
        self.marker.isDraggable = true
        self.marker.appearAnimation = .pop
        self.marker.map = mapView
        self.delegate = delegate
        
        if (lat == nil || lng == nil) {
            LocationManager.shared.delegate = self
            LocationManager.shared.startTracking()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Style
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = UIRectEdge()
        
        let navBar = self.navigationController?.navigationBar
        navBar?.barTintColor = .white
        navBar?.tintColor = Theme.Dark.textColor
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(cancelAction))
        
        // MapView
        self.mapView.translatesAutoresizingMaskIntoConstraints = false
        self.mapView.delegate = self
        self.view.addSubview(mapView)
        Helper.addConstraints(["H:|-0-[Map]-0-|", "V:|-0-[Map]-0-|"], source: view, views: ["Map" : mapView])

        searchBar.delegate = self
        searchBar.barTintColor = UIColor.white
        searchBar.sizeToFit()
        self.navigationItem.titleView = searchBar

        if let txtSearch = searchBar.value(forKey: "_searchField") as? UITextField {
            txtSearch.borderStyle = .roundedRect
            txtSearch.placeholder = LocStr("EditorMap.SearchPlaceholder")
            txtSearch.font = Theme.Font.medium.withSize(14)
            txtSearch.textColor = UIColor(red: 0.486275, green: 0.486275, blue: 0.486275, alpha: 1.0) //7C7C7C
            txtSearch.layer.cornerRadius = 2.5
            txtSearch.layer.borderColor = UIColor(red: 0.784314, green: 0.784314, blue: 0.784314, alpha: 1.0).cgColor
            txtSearch.layer.borderWidth = 1.0
        }
        
        self.tableView.backgroundColor = .clear
        self.tableView.bounces = false
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 44.0
        self.tableView.register(UINib(nibName: "PlaceTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.separatorColor = UIColor(cgColor: Theme.Light.separator)
        self.tableView.tableFooterView = UIView()
        
        self.overlayView.addSubview(self.tableView)
        self.overlayView.frame = self.view.bounds
        self.tableView.frame = CGRect(origin: .zero, size: self.overlayView.frame.size)
        self.overlayView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        self.overlayView.layer.opacity = 0
        self.view.addSubview(self.overlayView)

        self.lblPlace.numberOfLines = 0
        self.lblPlace.backgroundColor = UIColor(white: 0, alpha: 0.8)
        self.lblPlace.textColor = Theme.Dark.tint
        self.lblPlace.font = Theme.Font.light.withSize(14)
        self.lblPlace.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.lblPlace)
        Helper.addConstraints(["H:|-0-[Label]-0-|", "V:[TlG]-0-[Label]"], source: view, views: ["Label":self.lblPlace,"TlG":topLayoutGuide])
        
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
            NSLayoutConstraint(item: btnSave, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -12),
            NSLayoutConstraint(),
        ])
        
        // Localization
        btnSave.setTitle(LocStr("Save"), for: .normal)
        if (self.lblPlace.text == nil) {
            self.lblPlace.text = LocStr("Editor.MapLocationTip")
        }
    }
    
    func cancelAction() {
        dismiss(animated: true, completion: nil)
    }
    
    func saveAction() {
        let location = self.marker.position
        self.delegate?.didFinishWithCoordinate(lat: location.latitude, lng: location.longitude, place: self.placeName, address: self.placeAddress)
        self.cancelAction()
    }
    
    func searchAction() {
        self.places = nil
        self.placesClient.autocompleteQuery(self.lastSearch, bounds: GMSCoordinateBounds(region: self.mapBounds), filter: nil, callback: { [weak self] (results, error) -> Void in
            guard (error == nil && results?.isEmpty == false), let myself = self else { return }

            myself.places = []
            for result in results! {
                if let id = result.placeID {
                    myself.lookupPlace(byId: id)
                }
            }
        })
    }

    func lookupPlace(byId id: String) {
        placesClient.lookUpPlaceID(id) { [unowned self] (place, error) in
            if (error == nil && self.places != nil), let place = place {
                let location = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
                let distance = Int(self.centerCoord.distance(from: location)) // Meters
                self.places!.append(Place(name: place.name, address: place.formattedAddress, coordinate: place.coordinate, distance: distance))
            }
        }
    }
    
    fileprivate func updatePlace(name: String, address: String?) {
        self.placeName = name
        self.placeAddress = address
        
        let attribs: [String: Any] = [NSFontAttributeName: Theme.Font.medium.withSize(14)]
        
        guard address != nil else {
            self.lblPlace.attributedText = NSAttributedString(string: name, attributes: attribs)
            return
        }
        
        let strAttr = NSMutableAttributedString(string: name + "\n\(address!)")
        strAttr.addAttributes(attribs, range: NSRange(location: 0, length: name.characters.count))
        self.lblPlace.attributedText = strAttr
    }
}

extension EditorMapViewController: LocationManagerDelegate, GMSMapViewDelegate {
    
    func didChangeDirection(_ direction: CLLocationDirection) {}
    
    func didChangeLocationPermission(_ status: PermissionStatus) {}
    
    // MARK: - Location manager delegate
    func didChangeLocation(_ location: CLLocation) {
        LocationManager.shared.delegate = nil
        self.marker.position = location.coordinate
        self.mapView.moveTo(location.coordinate, withZoom: nil)
    }
    
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        self.marker.position = coordinate
    }
    
}

extension EditorMapViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.places?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let place = self.places?[indexPath.row] else { return UITableViewCell() }

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PlaceTableViewCell
        cell.lblTitle.text = place.name
        cell.lblDetail.text = place.address
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let place = self.places?[indexPath.row] else { return }
        
        self.mapView.animate(to: GMSCameraPosition.camera(withTarget: place.coordinate, zoom: 16))
        self.marker.position = place.coordinate
        self.searchBar.text = nil
        self.searchBar.resignFirstResponder()
        self.updatePlace(name: place.name, address: place.address?.trim())
    }
    
}

// MARK: - UISearchBar Delegate
extension EditorMapViewController: UISearchBarDelegate {
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = false
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let text = searchText.trim(false)!
        
        if (text.caseInsensitiveCompare(self.lastSearch) == .orderedSame) {
            return
        }
        
        self.lastSearch = text
        self.searchTimer?.invalidate()
        
        if (text.isEmpty) {
            self.places = nil
            return
        }
        
        if (text.characters.count < 2) {
            return
        }
        
        self.searchTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(searchAction), userInfo: nil, repeats: false)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.isSearching = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.isSearching = false
        self.places = nil
        self.lastSearch = ""
    }
}

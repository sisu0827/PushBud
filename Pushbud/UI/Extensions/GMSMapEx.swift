//
//  GMSMapEx.swift
//  Pushbud
//
//  Created by Daria.R on 01/05/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit
import GoogleMaps

extension GMSMapView {
    
    func moveTo(_ position: CLLocationCoordinate2D, withZoom: Float? = 15) {
        var zoom: Float?
        if let requestedZoom = withZoom, requestedZoom > self.camera.zoom {
            zoom = requestedZoom
        }
        
        let region = self.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(region: region)
        if (!bounds.contains(position)) {
            let camera = GMSCameraPosition.camera(withTarget: position, zoom: zoom ?? self.camera.zoom)
            self.animate(to: camera)
        } else if (zoom != nil) {
            self.animate(toZoom: zoom!)
        }
    }
    
}

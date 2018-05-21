//
//  MapClusterItem.swift
//  Pushbud
//
//  Created by Daria.R on 4/26/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit
import GoogleMaps

class MapClusterItem: NSObject, GMUClusterItem {
    var placeId: Int
    var position: CLLocationCoordinate2D
    var image: UIImage?
    var imageUrl: String?
    
    init(_ location: CLLocationCoordinate2D, feedId: Int, image: UIImage?, imageUrl: String?) {
        self.position = location
        self.placeId = feedId
        self.image = image
        self.imageUrl = imageUrl
    }
}

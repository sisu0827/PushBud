//
//  APIClient.swift
//  PushBud
//
//  Created by Daria.R on 4/13/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class APIClient {

    static let baseURL: String = Config.main["APIURL"]!

    static var Headers = [String : String]()
    
    static var JsonHeaders: [String: String] {
        var headers = self.Headers
        headers["content-type"] = "application/json"
        return headers
    }
    
}

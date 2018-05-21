//
//  DeviceManager.swift
//  PushBud
//
//  Created by Tomasz Chodakowski-Malkiewicz on 04/08/16.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import Foundation
import CoreLocation

class DeviceManager {
    
    static func register(_ device: Device) {
        Config.shared.device = device
        
        var params: [String : String] = ["device_token": device.apnToken]
        if let deviceId = device.id {
            params["id"] = deviceId
        }
        
        print("\(params)")
        
        HTTP.New(APIClient.baseURL + "devices", type: .POST, params: params, headers: APIClient.JsonHeaders).start { response in
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("Device::Register-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            if statusCode == 200, let id: String = response.data.jsonDict().getValue("id") {
                Config.shared.device?.id = id
            } else {
                response.error?.record()
            }
        }
    }
    
}

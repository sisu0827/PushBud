//
//  TrackingManager.swift
//  PushBud
//
//  Created by Daria.R on 12/9/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import Foundation
import ObjectMapper

class TrackingManager {
    
    static func getList(callback: @escaping (Result<[Tracking]?, NSError?>) -> ()) {
        HTTP.New(APIClient.baseURL + "tracking", type: .GET, headers: APIClient.Headers).start { response in
            
            LoaderOverlay.shared.hide()
            
            let statusCode = response.statusCode ?? 0
            
            #if DEBUG
                print("TrackingList-HTTP\(statusCode)\n\(String(describing: response.data.jsonObject() as? NSArray))")
            #endif
            
            switch (statusCode) {
            case 204:
                callback(Result.Success(nil))
            case 200:
                let array = response.data.jsonObject() as! [[String : Any]]
                callback(Result.Success(try? Mapper<Tracking>().mapArray(JSONObject: array)))
            default:
                callback(Result.Failure(response.error))
            }
        }
    }
    
    static func toggleInvitation(_ id: Int, value: Bool, callback: @escaping (Result<Bool, NSError?>) -> ()) {
        let type: Verb = value ? .PUT : .DELETE
        HTTP.New(APIClient.baseURL + "tracking?id=\(id)", type: type, headers: APIClient.Headers).start { response in
            
            let statusCode = response.statusCode ?? 0
            
            #if DEBUG
                print("Invitation\(type)-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            #endif
            
            switch (statusCode) {
            case 200:
                callback(Result.Success(true))
            default:
                callback(Result.Failure(response.error))
            }
        }
    }

}

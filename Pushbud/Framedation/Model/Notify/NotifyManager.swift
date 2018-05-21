//
//  NotifyManager.swift
//  PushBud
//
//  Created by Daria.R on 19/06/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import Foundation
import ObjectMapper

class NotifyManager {
    
    static var count: Int?

    static func fetchAll(params: HTTPParameterProtocol, callback:@escaping (Result<[Notify]?, NSError?>) -> ()) {
        HTTP.New(APIClient.baseURL + "notifications", type: .GET, params: params, headers: APIClient.Headers).start { response in
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("Notifs-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            switch (statusCode) {
            case 204:
                callback(Result.Success(nil))
                return
            case 200:
                break
            default:
                DLog("Notifs::FetchAll: \(response.error?.localizedDescription ?? "")", level: .error)
                callback(Result.Failure(response.error))
                return
            }
            
            if let json = response.data.jsonObject(), let items = try? Mapper<Notify>().mapArray(JSONObject: json) {
                callback(Result.Success(items))
            } else {
                callback(Result.Success(nil))
            }
            
        }
    }
    
//    static func removeNotification(byId id: Int, callback: @escaping (Result<Bool, NSError?>) -> ()) {
//        HTTP.New(APIClient.baseURL + "notifications", type: .DELETE, params: ["id": id], headers: APIClient.JsonHeaders).start { response in
//
//            let statusCode = response.statusCode ?? 0
//
//            if (Config.IsDevelopmentMode) {
//                print("NotificationDelete-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
//            }
//
//            switch (statusCode) {
//            case 200:
//                self.count = nil
//                callback(Result.Success(true))
//            default:
//                callback(Result.Failure(response.error))
//            }
//
//        }
//    }
}

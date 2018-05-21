//
//  FeedManager.swift
//  PushBud
//
//  Created by Daria.R on 4/13/17.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import Foundation
import ObjectMapper

class FeedManager {
    
    static func get(params: [String : Any], callback:@escaping (Result<(Int?, [Feed])?, NSError?>)->Void) {

        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        HTTP.New(APIClient.baseURL + "events", type: .GET, params: params, headers: APIClient.Headers).start { response in
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("Events-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            switch (statusCode) {
            case 204:
                callback(Result.Success(nil))
                return
            case 200:
                let dict = response.data.jsonObject() as! [String : Any]
                if let json = dict["events"] as? [[String : Any]], let feeds = try? Mapper<Feed>().mapArray(JSONObject: json) {
                    callback(Result.Success((dict["total_records"] as? Int, feeds)))
                    return
                }
            default:
                response.error?.record()
            }
            
            DLog("Events::GET: \(response.error?.localizedDescription ?? "")", level: .error)
            callback(Result.Failure(response.error))
        }
    }
    
    static func setLike(_ value: Bool, feedId: Int, callback: @escaping (Result<Bool, NSError?>) -> ()) {
        HTTP.New(APIClient.baseURL + "events/like", type: .PUT, params: ["event_id":feedId,"like":value], headers: APIClient.JsonHeaders).start { response in
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("EventLikeToggle-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            if (statusCode == 200) {
                callback(Result.Success(true))
            } else {
                callback(Result.Failure(response.error))
            }
        }
    }
    
    static func setReport(_ value: Bool, feedId: Int, callback: @escaping (Result<Bool, NSError?>) -> ()) {
        HTTP.New(APIClient.baseURL + "events/report", type: .PUT, params: ["event_id":feedId,"report":value], headers: APIClient.JsonHeaders).start { response in
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("EventReportToggle-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            if (statusCode == 200) {
                callback(Result.Success(true))
            } else {
                callback(Result.Failure(response.error))
            }
        }
    }
    
    static func saveEvent(_ values: HTTPParameterProtocol, callback: @escaping (Result<Feed, NSError?>) -> ()) {
        HTTP.New(APIClient.baseURL + "events", type: .POST, params: values, headers: APIClient.JsonHeaders).start { response in

            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("CreateEvent-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            guard let dict = response.data.jsonObject() as? [String : Any] else {
                callback(Result.Failure(response.error))
                return
            }
            
            if statusCode == 200 {
                do {
                    let item = try Mapper<Feed>().map(JSONObject: dict)
                    callback(Result.Success(item))
                } catch let mapperError as MapError {
                    callback(Result.Failure(PbError.error(mapperError.description)))
                } catch {
                    callback(Result.Failure(nil))
                }
            } else if let apiError: String = dict["error"] as? String {
                callback(Result.Failure(PbError.error(apiError)))
            } else {
                callback(Result.Failure(response.error))
            }
        }
    }
    
}

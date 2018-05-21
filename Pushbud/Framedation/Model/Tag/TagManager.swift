//
//  TagManager.swift
//  PushBud
//
//  Created by Daria.R on 4/13/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import Foundation
import ObjectMapper

class TagManager {
    
    static func getPopularTags(withLimit limit: Int, callback: @escaping (Result<[Tag], NSError?>) -> ()) {
        HTTP.New(APIClient.baseURL + "tags/popular", type: .GET, params: ["limit": limit], headers: APIClient.Headers).start { response in
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("Tag-Popular\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            switch (statusCode) {
            case 204:
                callback(Result.Success([]))
                return
            case 200:
                if let array = response.data.jsonObject() as? [[String : Any]], let tags = try? Mapper<Tag>().mapArray(JSONArray: array) {
                    callback(Result.Success(tags))
                    return
                }
            default:
                response.error?.record()
            }
            
            callback(Result.Failure(response.error))
        }
    }
    
    static func toggle(follow: Bool, for id: Int, callback: @escaping (Result<Bool, NSError?>) -> ()) {
        HTTP.New(APIClient.baseURL + "follow", type: follow ? .POST : .DELETE, params: ["tag_id": id], headers: APIClient.JsonHeaders).start { response in
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("TagFollow-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            switch (statusCode) {
            case 200:
                callback(Result.Success(true))
            default:
                callback(Result.Failure(response.error))
            }
        }
    }
    
}

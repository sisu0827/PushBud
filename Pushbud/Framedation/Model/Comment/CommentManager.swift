//
//  CommentManager.swift
//  PushBud
//
//  Created by Daria.R on 31/07/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import Foundation
import ObjectMapper

class CommentManager {
    
    static func fetch(by feedId: Int, callback:@escaping (Result<[FeedComment]?, NSError?>) -> ()) {
        HTTP.New(APIClient.baseURL + "comments?event_id=\(feedId)", type: .GET, headers: APIClient.Headers).start { response in
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("Comments-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            switch (statusCode) {
            case 204:
                callback(Result.Success(nil))
                return
            case 200:
                break
            default:
                DLog("Feed::FetchAll: \(response.error?.localizedDescription ?? "")", level: .error)
                callback(Result.Failure(response.error))
                return
            }
            
            if let json = response.data.jsonObject(), let items = try? Mapper<FeedComment>().mapArray(JSONObject: json) {
                callback(Result.Success(items))
            } else {
                callback(Result.Success(nil))
            }
        }
    }
    
    static func setLike(for id: Int, value: Bool, callback: @escaping (Result<Bool, NSError?>) -> ()) {
        let url = APIClient.baseURL + "comments/like"
        HTTP.New(url, type: .PUT, params: ["comment_id": id, "like": value], headers: APIClient.JsonHeaders).start { response in
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("CommentLikeToggle-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            if (statusCode == 200) {
                callback(Result.Success(true))
            } else {
                callback(Result.Failure(response.error))
            }
        }
    }
    
}

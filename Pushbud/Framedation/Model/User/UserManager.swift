//
//  UserManager.swift
//  PushBud
//
//  Created by Daria.R on 4/13/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import Foundation
import ObjectMapper

class UserManager {
    
    static func authenticate(action: String, username: String, password: String, callback: @escaping (Result<User, String?>) -> ()) {
        HTTP.New(APIClient.baseURL + "auth/" + action, type: .POST, params: ["username": username, "password": password], headers: APIClient.JsonHeaders).start { response in
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("Auth-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            let dict = response.data.jsonObject() as? [String: Any]
            
            if (statusCode == 200), let user = self.parseAndSaveUser(dict) {
                callback(Result.Success(user))
                return
            }
            
            var error: String?
            if dict != nil, let apiError: String = dict!["error"] as? String, apiError.hasPrefix("APIError.") {
                error = LocStr(apiError)
                if (apiError == "APIError.LoginExist") {
                    error = String(format: error!, username)
                }
            }
            
            let origError = response.error?.localizedDescription
            DLog("UserManager::\(action): \(error ?? origError ?? "")", level: .error)
            response.error?.record()
            callback(Result.Failure(error ?? origError))
        }
    }
    
    static func addConnection(_ userId: Int, callback: @escaping (Result<Bool, NSError?>) -> ()) {
        HTTP.New(APIClient.baseURL + "friends", type: .POST, params: ["user_id": userId], headers: APIClient.JsonHeaders).start { response in
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("UserFollow-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            switch (statusCode) {
            case 200:
                callback(Result.Success(true))
            default:
                callback(Result.Failure(response.error))
            }
        }
    }
    
    static func toggleInvitation(_ friendshipId: Int, value: Bool, callback: @escaping (Result<Bool, NSError?>) -> ()) {
        let params: [String: Any] = ["friendship_id": friendshipId, "is_accepted": value]
        HTTP.New(APIClient.baseURL + "friends", type: .PUT, params: params, headers: APIClient.JsonHeaders).start { response in
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("ToggleInvitation-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            switch (statusCode) {
            case 200:
                callback(Result.Success(true))
            default:
                callback(Result.Failure(response.error))
            }
        }
    }
    
    static func removeFriendship(_ friendshipId: Int, callback: @escaping (Result<Bool, NSError?>) -> ()) {
        HTTP.New(APIClient.baseURL + "friends", type: .DELETE, params: ["friendship_id": friendshipId], headers: APIClient.JsonHeaders).start { response in
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("UnfollowUser-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            switch (statusCode) {
            case 200:
                callback(Result.Success(true))
            default:
                callback(Result.Failure(response.error))
            }
        }
    }
    
    static func saveProfile(_ params: HTTPParameterProtocol, callback: @escaping (Result<Bool, String>) -> ()) {
        if (Config.IsDevelopmentMode) {
            print("NewProfile: \(params)")
        }
        
        HTTP.New(APIClient.baseURL + "users", type: .PUT, params: params, headers: APIClient.JsonHeaders).start { response in
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("SaveProfile-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            if (statusCode == 200) {
                callback(Result.Success(true))
                return
            }

            let error: String
            if let apiError = response.data.apiError {
                error = apiError
            } else if (response.error?.isNetworkError == true) {
                error = "Error.NoNetworkTip"
            } else {
                error = "Error.Unexpected"
            }
            
            callback(Result.Failure(LocStr(error)))
        }
    }
    
    static func savePassword(password: String, newPassword: String, callback: @escaping (Result<Bool, String>) -> ()) {
        HTTP.New(APIClient.baseURL + "users", type: .PUT, params: ["old_password": password, "password": newPassword], headers: APIClient.JsonHeaders).start { response in
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("SavePassword-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            if (statusCode == 200) {
                callback(Result.Success(true))
                return
            }
            
            let error: String
            if let apiError = response.data.apiError {
                error = apiError
            } else if (response.error?.isNetworkError == true) {
                error = "Error.NoNetworkTip"
            } else {
                error = "Error.Unexpected"
            }
            
            callback(Result.Failure(LocStr(error)))
        }
    }
    
    static func storeProfile(_ profile: User) {
        let defaults = UserDefaults.standard
        defaults.set(profile.username, forKey: StorageConstants.username)
        defaults.set(profile.email, forKey: StorageConstants.userEmail)
        defaults.set(profile.name, forKey: StorageConstants.displayName)
        defaults.set(profile.picture, forKey: StorageConstants.profilePicture)
        defaults.synchronize()
        
        Config.userProfile = profile
    }

    static func logout() {
        Keychain.unset("Credential")
        APIClient.Headers.removeValue(forKey: "Authorization")
        Config.userProfile = nil
        StorageConstants.authKeys.forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
        UserDefaults.standard.synchronize()
    }
    
    static func authenticateFromStorage() -> Bool {
        let defaults = UserDefaults.standard
        
        guard
            let values = Keychain.get("Credential")?.components(separatedBy: "$#||#$"), values.count == 2,
            let userId = Int(values[0]), let username = defaults.string(forKey: StorageConstants.username)
        else {
            return false
        }
        
        APIClient.Headers["Authorization"] = "Bearer " + values[1]
        
        let profile = User(
            id: userId,
            name: defaults.string(forKey: StorageConstants.displayName),
            username: username,
            email: defaults.string(forKey: StorageConstants.userEmail),
            picture: defaults.string(forKey: StorageConstants.profilePicture)
        )
        Config.userProfile = profile
        
        return true
    }

    // MARK: - Private
    private static func parseAndSaveUser(_ dict: [String : Any]?) -> User? {
        guard
            let userDict = dict?["user"] as? [String : Any],
            let userProfile = try? Mapper<User>().map(JSON: userDict),
            let token = dict!["token"] as? String
        else {
            return nil
        }

        Keychain.set("\(userProfile.id)$#||#$" + token, forKey: "Credential")
        storeProfile(userProfile)
        APIClient.Headers["Authorization"] = "Bearer " + token
        
        return userProfile
    }
    
}

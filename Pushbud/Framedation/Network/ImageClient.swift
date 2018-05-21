//
//  ImageClient.swift
//  PushBud
//
//  Created by Daria.R on 4/13/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class ImageClient: NSObject {
    
    class var shared: ImageClient {
        struct Static {
            static let instance = ImageClient()
        }
        return Static.instance
    }

    private let queue = DispatchQueue(label: "com.pushbud.ImageLoader", qos: .background)
    private let cache = NSCache<AnyObject, AnyObject>()

    let getUrl = "https://assets.pushbud.no/images/"
    let putUrl = "http://images.pushbud.no/api/upload"
    
    let session: URLSession

    init(configuration: URLSessionConfiguration) {
        self.session = URLSession(configuration: configuration)
    }
    
    override convenience init() {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringCacheData
        self.init(configuration: configuration)
    }
    
    static func scaledUriParam(for size: Int) -> String {
        return "\(size * Int(Constants.screenScale))/"
    }
    
    /* func upload(_ data: Data, callback: @escaping (String?, NSError?) -> ()) {
        let params = ["image": Upload(data: data, fileName: NSUUID().uuidString + ".jpg", mimeType: "")]
        let opt = HTTP.New(self.putUrl, type: .POST, params: params, headers: APIClient.Headers, serializer: HTTPSerializer(isUpload: true))
        opt.progress = { progress in
            DispatchQueue.main.async {
                LoaderOverlay.shared.progress?.animate(toAngle: Double(progress) * 360.0)
            }
        }
        opt.start { response in
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("ImageUpload::HTTP\(statusCode): \(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            if (statusCode == 200), let filename: String = response.data.jsonDict().getValue("Key") {
                callback(filename, nil)
            } else {
                callback(nil, response.error)
            }
       }
    } */
    
    func requestKey(ofType type: String, and fileType: String = "jpg", callback:@escaping (Result<(URL, String), NSError?>) -> ()) {
        HTTP.New("https://sign.pushbud.no/", type: .POST, params: ["type": type, "fileType": fileType], headers: APIClient.JsonHeaders).start { response in
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("RequestKey-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            if statusCode == 200, let strUrl: String = response.data.jsonDict().getValue("url"), let url = URL(string: strUrl) {
                callback(Result.Success((url, response.data.jsonDict().getValue("event_picture_url") ?? "")))
            } else {
                callback(Result.Failure(response.error))
            }
        }
    }
    
    func uploader(_ url: URL, imageData: Data) -> HTTP {
        var request = URLRequest(url: url)
        request.timeoutInterval = 180
        request.httpMethod = "PUT"
        request.httpBody = imageData
        return HTTP(request)
    }
    
    func setCached(data: Data, for url: String) {
        self.cache.setObject(data as AnyObject, forKey: url as AnyObject)
    }
    
    func getCached(_ url: String) -> UIImage? {
        if let data = self.cache.object(forKey: url as AnyObject) as? Data {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    func download(_ url: String, handler:@escaping (UIImage?, String, Bool) -> Void) {
        guard let imageUrl = URL(string: self.getUrl + url) else {
            if (Config.IsDevelopmentMode) {
                print("ImageDownload::Invalid-URL::\(self.getUrl + url)")
            }
            handler(nil, url, false)
            return
        }
        
        // Cache
        if let image = self.getCached(url) {
            handler(image, url, true)
            return
        }
        
        queue.async {
            let task = self.session.dataTask(with: imageUrl) { (data: Data?, response: URLResponse?, error: Error?) in
                var image: UIImage?
                
                defer {
                    DispatchQueue.main.async{ handler(image, url, false) }
                }
                
                if error == nil, let i = data?.toImage {
                    image = i
                    self.cache.setObject(data as AnyObject, forKey: url as AnyObject)
                    return
                }
                
                #if DEBUG
                    print("ImageDownload::Failure::\(self.getUrl + url)")
                #endif
            }
            task.resume()
            
        }
    }
    
}

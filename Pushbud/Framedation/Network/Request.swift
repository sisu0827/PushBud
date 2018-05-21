//
//  Request.swift
//  SwiftHTTP
//
//  Created by Dalton Cherry on 8/16/15.
//  Copyright © 2015 vluxe. All rights reserved.
//

import Foundation

/**
 The standard HTTP Verbs
 */
enum Verb: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case HEAD = "HEAD"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
    case OPTIONS = "OPTIONS"
    case TRACE = "TRACE"
    case CONNECT = "CONNECT"
    case UNKNOWN = "UNKNOWN"
}

/**
 This is used to create key/value pairs of the parameters
 */
struct HTTPPair {
    var key: String?
    let storeVal: AnyObject
    /**
     Create the object with a possible key and a value
     */
    init(key: String?, value: AnyObject) {
        self.key = key
        self.storeVal = value
    }
    /**
     Computed property of the string representation of the storedVal
     */
    var upload: Upload? {
        return storeVal as? Upload
    }
    /**
     Computed property of the string representation of the storedVal
     */
    var value: String {
        if storeVal is NSNull {
            return ""
        } else if let v = storeVal as? String {
            return v
        }
        return storeVal.description ?? ""
    }
    /**
     Computed property of the string representation of the storedVal escaped for URLs
     */
    var escapedValue: String {
        let v = value.escaped ?? ""

        if let k = key?.escaped {
            return "\(k)=\(v)"
        }
        
        return v
    }
}

/**
 Enum used to describe what kind of Parameter is being interacted with.
 This allows us to only support an Array or Dictionary and avoid having to use AnyObject
 */
enum HTTPParamType {
    case array
    case dictionary
    case upload
}

/**
 This protocol is used to make the dictionary and array serializable into key/value pairs.
 */
protocol HTTPParameterProtocol {
    func paramType() -> HTTPParamType
    func createPairs(_ key: String?) -> Array<HTTPPair>
}

/**
 Support for the Dictionary type as an HTTPParameter.
 */
extension Dictionary: HTTPParameterProtocol {
    func paramType() -> HTTPParamType {
        return .dictionary
    }
    func createPairs(_ key: String?) -> Array<HTTPPair> {
        var collect = Array<HTTPPair>()
        for (k, nestedVal) in self {
            guard let nestedKey = k as? String else {
                continue
            }

            let useKey = key == nil ? nestedKey : "\(key!)[\(nestedKey)]"

            if let subParam = nestedVal as? Dictionary {
                collect.append(contentsOf: subParam.createPairs(useKey))
            } else if let subParam = nestedVal as? Array<AnyObject> {
                collect.append(contentsOf: subParam.createPairs(useKey))
            } else {
                collect.append(HTTPPair(key: useKey, value: nestedVal as AnyObject))
            }
        }
        return collect
    }
}

/**
 Support for the Array type as an HTTPParameter.
 */
extension Array: HTTPParameterProtocol {
    func paramType() -> HTTPParamType {
        return .array
    }
    
    func createPairs(_ key: String?) -> Array<HTTPPair> {
        var collect = Array<HTTPPair>()
        for nestedVal in self {

            let useKey = key != nil ? "\(key!)[]" : key

            if let subParam = nestedVal as? Dictionary<String, AnyObject> {
                collect.append(contentsOf: subParam.createPairs(useKey))
            } else if let subParam = nestedVal as? Array<AnyObject> {
                collect.append(contentsOf: subParam.createPairs(useKey))
            } else {
                collect.append(HTTPPair(key: useKey, value: nestedVal as AnyObject))
            }
        }
        return collect
    }
}

/**
 Support for the Upload type as an HTTPParameter.
 */
extension Upload: HTTPParameterProtocol {
    func paramType() -> HTTPParamType {
        return .upload
    }
    
    func createPairs(_ key: String?) -> Array<HTTPPair> {
        var collect = Array<HTTPPair>()
        collect.append(HTTPPair(key: key, value: self))
        return collect
    }
}

/**
 Adds convenience methods to NSMutableURLRequest to make using it with HTTP much simpler.
 */
extension NSMutableURLRequest {
    /**
     Convenience init to allow init with a string.
     -parameter urlString: The string representation of a URL to init with.
     */
    convenience init?(urlString: String) {
        if let url = URL(string: urlString) {
            self.init(url: url)
        } else {
            return nil
        }
    }
    
    /**
     Convenience method to avoid having to use strings and allow using an enum
     */
    var verb: Verb {
        set {
            httpMethod = newValue.rawValue
        }
        get {
            if let v = Verb(rawValue: httpMethod) {
                return v
            }
            return .UNKNOWN
        }
    }
    
    /**
     Used to update the content type in the HTTP header as needed
     */
    var contentTypeKey: String {
        return "Content-Type"
    }
    
    /**
     append the parameters using the standard HTTP Query model.
     This is parameters in the query string of the url (e.g. ?first=one&second=two for GET, HEAD, DELETE.
     It uses 'application/x-www-form-urlencoded' for the content type of POST/PUT requests that don't contains files.
     If it contains a file it uses `multipart/form-data` for the content type.
     -parameter parameters: The container (array or dictionary) to convert and append to the URL or Body
     */
    func appendParameters(_ parameters: HTTPParameterProtocol) {
        if isURIParam() {
            appendParametersAsQueryString(parameters)
        } else {
            appendParametersAsUrlEncoding(parameters)
        }
    }
    
    /**
     append the parameters as a HTTP Query string. (e.g. domain.com?first=one&second=two)
     -parameter parameters: The container (array or dictionary) to convert and append to the URL
     */
    func appendParametersAsQueryString(_ parameters: HTTPParameterProtocol) {
        let queryString = parameters.createPairs(nil).map({ (pair) in
            return pair.escapedValue
        }).joined(separator: "&")
        if let u = self.url , queryString.characters.count > 0 {
            let para = u.query != nil ? "&" : "?"
            self.url = URL(string: "\(u.absoluteString)\(para)\(queryString)")
        }
    }
    
    /**
     append the parameters as a url encoded string. (e.g. in the body of the request as: first=one&second=two)
     -parameter parameters: The container (array or dictionary) to convert and append to the HTTP body
     */
    func appendParametersAsUrlEncoding(_ parameters: HTTPParameterProtocol) {
        if value(forHTTPHeaderField: contentTypeKey) == nil {
            let encoding = CFStringConvertNSStringEncodingToEncoding(String.Encoding.utf8.rawValue)
            setValue("application/x-www-form-urlencoded; charset=\(CFStringConvertEncodingToIANACharSetName(encoding))",
                     forHTTPHeaderField:contentTypeKey)
            
        }
        let queryString = parameters.createPairs(nil).map({ (pair) in
            return pair.escapedValue
        }).joined(separator: "&")
        httpBody = queryString.data(using: String.Encoding.utf8)
    }
    
    /**
     append the parameters as a multpart form body. This is the type normally used for file uploads.
     -parameter parameters: The container (array or dictionary) to convert and append to the HTTP body
     */
    func appendParametersAsMultiPartFormData(_ parameters: HTTPParameterProtocol) {
        let boundary = "Boundary+\(arc4random())\(arc4random())"
        if value(forHTTPHeaderField: contentTypeKey) == nil {
            setValue("multipart/form-data; boundary=\(boundary)",
                     forHTTPHeaderField:contentTypeKey)
        }
        let mutData = NSMutableData()
        let multiCRLF = "\r\n"
        mutData.append("--\(boundary)".data(using: String.Encoding.utf8)!)
        for pair in parameters.createPairs(nil) {
            guard let key = pair.key else { continue } //this won't happen, but just to properly unwrap
            mutData.append("\(multiCRLF)".data(using: String.Encoding.utf8)!)
            if let upload = pair.upload, let uploadData = upload.getData() {
                mutData.append(multiFormHeader(key, fileName: upload.fileName,
                    type: upload.mimeType, multiCRLF: multiCRLF).data(using: String.Encoding.utf8)!)
                mutData.append(uploadData as Data)
            } else {
                let str = "\(multiFormHeader(key, fileName: nil, type: nil, multiCRLF: multiCRLF))\(pair.value)"
                mutData.append(str.data(using: String.Encoding.utf8)!)
            }
            mutData.append("\(multiCRLF)--\(boundary)".data(using: String.Encoding.utf8)!)
        }
        mutData.append("--\(multiCRLF)".data(using: String.Encoding.utf8)!)
        httpBody = mutData as Data
    }
    
    /**
     Helper method to create the multipart form data
     */
    func multiFormHeader(_ name: String, fileName: String?, type: String?, multiCRLF: String) -> String {
        var str = "Content-Disposition: form-data; name=\"\(name.escaped!)\""
        if let name = fileName {
            str += "; filename=\"\(name)\""
        }
        str += multiCRLF
        if let t = type {
            str += "Content-Type: \(t)\(multiCRLF)"
        }
        str += multiCRLF
        return str
    }
    
    /**
     Check if the request requires the parameters to be appended to the URL
     */
    func isURIParam() -> Bool {
        switch (verb) {
        case .GET,.HEAD,.POST:
            return true
        default:
            return false
        }
    }
}

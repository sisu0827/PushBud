//
//  Operation.swift
//  SwiftHTTP
//
//  Created by Dalton Cherry on 8/2/15.
//  Copyright © 2015 vluxe. All rights reserved.
//

import Foundation

enum HTTPOptError: Error {
    case invalidRequest
}

/**
 This protocol exist to allow easy and customizable swapping of a serializing format within an class methods of HTTP.
 */
protocol HTTPSerializeProtocol {
    
    /**
     implement this protocol to support serializing parameters to the proper HTTP body or URL
     -parameter request: The NSMutableURLRequest object you will modify to add the parameters to
     -parameter parameters: The container (array or dictionary) to convert and append to the URL or Body
     */
    func serialize(_ request: NSMutableURLRequest, parameters: HTTPParameterProtocol)
}

/**
 Standard HTTP encoding
 */
struct HTTPSerializer: HTTPSerializeProtocol {
    var isUpload: Bool
    init(isUpload: Bool = false) {
        self.isUpload = isUpload
    }
    func serialize(_ request: NSMutableURLRequest, parameters: HTTPParameterProtocol) {
        if (self.isUpload) {
            request.appendParametersAsMultiPartFormData(parameters)
        } else {
            request.appendParameters(parameters)
        }
    }
}

/**
 Send the data as a JSON body
 */
struct JSONSerializer: HTTPSerializeProtocol {
    init() { }
    func serialize(_ request: NSMutableURLRequest, parameters: HTTPParameterProtocol) {
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters as AnyObject, options: JSONSerialization.WritingOptions())
        } catch { }
    }
}

/**
 All the things of an HTTP response
 */
open class Response {
    /// The header values in HTTP response.
    open var headers: Dictionary<String,String>?
    /// The mime type of the HTTP response.
    open var mimeType: String?
    /// The suggested filename for a downloaded file.
    open var suggestedFilename: String?
    /// The body data of the HTTP response.
    open var data: Data {
        return collectData as Data
    }
    /// The status code of the HTTP response.
    open var statusCode: Int?
    /// The URL of the HTTP response.
    open var URL: Foundation.URL?
    /// The Error of the HTTP response (if there was one).
    open var error: NSError?
    ///Returns the response as a string
    open var text: String? {
        return String(data: data, encoding: .utf8)
    }
    ///get the description of the response
    open var description: String {
        var buffer = ""
        if let u = URL {
            buffer += "URL:\n\(u)\n\n"
        }
        if let code = self.statusCode {
            buffer += "Status Code:\n\(code)\n\n"
        }
        if let heads = headers {
            buffer += "Headers:\n"
            for (key, value) in heads {
                buffer += "\(key): \(value)\n"
            }
            buffer += "\n"
        }
        if let t = text {
            buffer += "Payload:\n\(t)\n"
        }
        return buffer
    }
    ///private things
    
    ///holds the collected data
    var collectData = NSMutableData()
    ///finish closure
    var completionHandler:((Response) -> Void)?
    
    //progress closure. Progress is between 0 and 1.
    var progressHandler:((Float) -> Void)?
    
    ///This gets called on auth challenges. If nil, default handling is use.
    ///Returning nil from this method will cause the request to be rejected and cancelled
    var auth:((URLAuthenticationChallenge) -> URLCredential?)?
    
    ///This is for doing SSL pinning
    var security: HTTPSecurity?
}

/**
 The class that does the magic. Is a subclass of NSOperation so you can use it with operation queues or just a good ole HTTP request.
 */
class HTTP: Operation {
    
    /**
     Get notified with a request finishes.
     */
    var onFinish:((Response) -> Void)? {
        didSet {
            if let handler = onFinish {
                DelegateManager.shared.addTask(task, completionHandler: { (response: Response) in
                    self.finish()
                    handler(response)
                })
            }
        }
    }
    
    ///This is for doing SSL pinning
    var security: HTTPSecurity? {
        set {
            guard let resp = DelegateManager.shared.responseForTask(task) else { return }
            resp.security = newValue
        }
        get {
            guard let resp = DelegateManager.shared.responseForTask(task) else { return nil }
            return resp.security
        }
    }
    
    ///This is for monitoring progress
    var progress: ((Float) -> Void)? {
        set {
            guard let resp = DelegateManager.shared.responseForTask(task) else { return }
            resp.progressHandler = newValue
        }
        get {
            guard let resp = DelegateManager.shared.responseForTask(task) else { return nil }
            return resp.progressHandler
        }
    }
    
    ///the actual task
    var task: URLSessionDataTask!
    /// Reports if the task is currently running
    private var running = false
    /// Reports if the task is finished or not.
    private var done = false
    /// Reports if the task is cancelled
    private var _cancelled = false
    
    /**
     creates a new HTTP request.
     */
    init(_ req: URLRequest, session: URLSession = SharedSession.defaultSession) {
        super.init()
        task = session.dataTask(with: req)
        DelegateManager.shared.addResponseForTask(task)
    }
    
    //MARK: Subclassed NSOperation Methods
    
    /// Returns if the task is asynchronous or not. NSURLSessionTask requests are asynchronous.
    override var isAsynchronous: Bool {
        return true
    }
    
    /// Returns if the task is current running.
    override var isExecuting: Bool {
        return running
    }
    
    /// Returns if the task is finished.
    override var isFinished: Bool {
        return done && !_cancelled
    }
    
    /**
     start/sends the HTTP task with a completionHandler. Use this when *NOT* using an NSOperationQueue.
     */
    func start(_ completionHandler:@escaping ((Response) -> Void)) {
        onFinish = completionHandler
        start()
    }
    
    /**
     Start the HTTP task. Make sure to set the onFinish closure before calling this to get a response.
     */
    override func start() {
        if isCancelled {
            self.willChangeValue(forKey: "isFinished")
            done = true
            self.didChangeValue(forKey: "isFinished")
            return
        }
        
        self.willChangeValue(forKey: "isExecuting")
        self.willChangeValue(forKey: "isFinished")
        
        running = true
        done = false
        
        self.didChangeValue(forKey: "isExecuting")
        self.didChangeValue(forKey: "isFinished")
        
        task.resume()
    }
    
    /**
     Cancel the running task
     */
    override func cancel() {
        task.cancel()
        _cancelled = true
        finish()
    }
    /**
     Sets the task to finished.
     If you aren't using the DelegateManager, you will have to call this in your delegate's URLSession:dataTask:didCompleteWithError: method
     */
    func finish() {
        self.willChangeValue(forKey: "isExecuting")
        self.willChangeValue(forKey: "isFinished")
        
        running = false
        done = true
        
        self.didChangeValue(forKey: "isExecuting")
        self.didChangeValue(forKey: "isFinished")
    }
    
    /**
     Class method to create a HTTP request that handles the NSMutableURLRequest and parameter encoding for you.
     */
    class func New(_ url: String, type: Verb, params: HTTPParameterProtocol? = nil, headers: [String: String]? = nil, serializer: HTTPSerializeProtocol? = nil) -> HTTP {
        let req = NSMutableURLRequest(urlString: url)!
        if let handler = DelegateManager.shared.requestHandler {
            handler(req)
        }
        req.verb = type
        if params != nil {
            (serializer ?? (type == .GET ? HTTPSerializer() : JSONSerializer())).serialize(req, parameters: params!)
        }
        for (key,value) in (headers ?? APIClient.Headers) {
            req.addValue(value, forHTTPHeaderField: key)
        }
        print("API Profiling Start: \(url)")
        return HTTP(req as URLRequest)
    }
    
    /**
     Set the global auth handler
     */
    class func globalAuth(_ handler: ((URLAuthenticationChallenge) -> URLCredential?)?) {
        DelegateManager.shared.auth = handler
    }
    
    /**
     Set the global security handler
     */
    class func globalSecurity(_ security: HTTPSecurity?) {
        DelegateManager.shared.security = security
    }
    
    /**
     Set the global request handler
     */
    class func globalRequest(_ handler: ((NSMutableURLRequest) -> Void)?) {
        DelegateManager.shared.requestHandler = handler
    }
}

/**
 Absorb all the delegates methods of NSURLSession and forwards them to pretty closures.
 This is basically the sin eater for NSURLSession.
 */
class DelegateManager: NSObject, URLSessionDataDelegate {
    //the singleton to handle delegate needs of NSURLSession
    static let shared = DelegateManager()
    
    /// this is for global authenication handling
    var auth:((URLAuthenticationChallenge) -> URLCredential?)?
    
    ///This is for global SSL pinning
    var security: HTTPSecurity?
    
    /// this is for global request handling
    var requestHandler:((NSMutableURLRequest) -> Void)?
    
    var taskMap = Dictionary<Int,Response>()
    //"install" a task by adding the task to the map and setting the completion handler
    func addTask(_ task: URLSessionTask, completionHandler:@escaping ((Response) -> Void)) {
        addResponseForTask(task)
        if let resp = responseForTask(task) {
            resp.completionHandler = completionHandler
        }
    }
    
    //"remove" a task by removing the task from the map
    func removeTask(_ task: URLSessionTask) {
        taskMap.removeValue(forKey: task.taskIdentifier)
    }
    
    //add the response task
    func addResponseForTask(_ task: URLSessionTask) {
        if taskMap[task.taskIdentifier] == nil {
            taskMap[task.taskIdentifier] = Response()
        }
    }
    //get the response object for the task
    func responseForTask(_ task: URLSessionTask) -> Response? {
        return taskMap[task.taskIdentifier]
    }
    
    //handle getting data
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        addResponseForTask(dataTask)
        guard let resp = responseForTask(dataTask) else { return }
        resp.collectData.append(data)
        if resp.progressHandler != nil { //don't want the extra cycles for no reason
            guard let taskResp = dataTask.response else { return }
            progressHandler(resp, expectedLength: taskResp.expectedContentLength, currentLength: Int64(resp.collectData.length))
        }
    }
    
    //handle task finishing
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let resp = responseForTask(task) else { return }
        resp.error = error as NSError?
        if let code = (task.response as? HTTPURLResponse)?.statusCode {
            resp.statusCode = code
            if (code > 299) {
                resp.error = createError(code)
            }
        }
        
        if let handler = resp.completionHandler {
            DispatchQueue.main.async(execute: { handler(resp) })
        }
        
        removeTask(task)
    }
    
    //upload progress
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let resp = responseForTask(task) else { return }
        progressHandler(resp, expectedLength: totalBytesExpectedToSend, currentLength: totalBytesSent)
    }
    //download progress
    func URLSession(_ session: Foundation.URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let resp = responseForTask(downloadTask) else { return }
        progressHandler(resp, expectedLength: totalBytesExpectedToWrite, currentLength: bytesWritten)
    }
    
    //handle progress
    func progressHandler(_ response: Response, expectedLength: Int64, currentLength: Int64) {
        guard let handler = response.progressHandler else { return }

        handler( (Float(1.0) / Float(expectedLength)) * Float(currentLength) )
    }
    
    /**
     Create an error for response you probably don't want (400-500 HTTP responses for example).
     
     -parameter code: Code for error.
     
     -returns An NSError.
     */
    private func createError(_ code: Int) -> NSError {
        let text = HTTPStatusCode(statusCode: code).statusDescription
        return NSError(domain: "HTTP", code: code, userInfo: [NSLocalizedDescriptionKey: text])
    }
}

/**
 Handles providing singletons of NSURLSession.
 */
class SharedSession {
    static let defaultSession = URLSession(configuration: URLSessionConfiguration.default,
                                             delegate: DelegateManager.shared, delegateQueue: nil)
    static let ephemeralSession = URLSession(configuration: URLSessionConfiguration.ephemeral,
                                               delegate: DelegateManager.shared, delegateQueue: nil)
}

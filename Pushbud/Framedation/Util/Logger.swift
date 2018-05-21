//
//  Logger.swift
//  PushBud
//
//  Created by Tomasz Chodakowski-Malkiewicz on 16/05/16.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import Foundation

public enum DLogLevel {
    case info
    case warning
    case error
    case hit
}
    
public func DLog<T>(_ object: T, level: DLogLevel = .info, filename: String = #file, line: Int = #line, funcname: String = #function) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = Constants.localDateFormatShort
    let process = ProcessInfo.processInfo
    let threadId = Thread.current
    let fileName = (filename as NSString).lastPathComponent
    var levelLabel = ""
    switch level {
    case .info: levelLabel = "ℹ️"
    case .warning: levelLabel = "⚠️"
    case .error: levelLabel = "☣️"
    case .hit: levelLabel = "🎯"
    }
    DLogLine("\(levelLabel) \(dateFormatter.string(from: Date())) \(process.processName))[\(process.processIdentifier):\(threadId)] \(fileName)(\(line)) \(funcname) :\r\t\(object)\n")
}
    
public func DLogFunc(_ filename: String = #file, line: Int = #line, funcname: String = #function) {
    DLog("", level: .hit, filename: filename, line: line, funcname: funcname)
}

public func DLogLine(_ text: String) {
    #if CONSOLE_LOG
        NSLog(text)
    #else
        print(text)
    #endif
}

/*
#else
    public func DLog<T>(object: T, level: DLogLevel = .Info) {}
    public func DLogFunc() {}
#endif
*/

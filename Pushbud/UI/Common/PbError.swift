//
//  PbError.swift
//  Pushbud
//
//  Created by Daria.R on 08/04/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import Foundation

class PbError {
    
    static let errorDomain = "pushbud.error"
    static let errorFuncKey = "pushbud.error.function"
    static let errorFileKey = "pushbud.error.file"
    static let errorLineKey = "pushbud.error.line"
    
    static func error(_ message: String, function: String = #function, file: String = #file, line: Int = #line) -> NSError {
        
        let customError = NSError(domain: errorDomain, code: 0, userInfo: [
            NSLocalizedDescriptionKey: message,
            errorFuncKey: function,
            errorFileKey: file,
            errorLineKey: line
        ])
        
        return customError
    }
}

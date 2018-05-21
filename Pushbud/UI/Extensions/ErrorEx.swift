//
//  ErrorEx.swift
//  Pushbud
//
//  Created by Daria.R on 12/06/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import Foundation
import Sentry

extension NSError {
    
    var isNetworkError: Bool {
        if (self.code == NSURLErrorTimedOut) {
            return true
        }
        
        if (self.domain != NSURLErrorDomain) {
            return false
        }
        
        switch (self.code) {
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorCannotConnectToHost:
            return true
        default:
            return false
        }
    }
    
    func record() {
        //Client.shared?.captureMessage(self.localizedFailureReason ?? self.localizedDescription)
        let event = Event(level: .error)
        event.message = self.localizedFailureReason ?? self.localizedDescription
        event.extra = ["ios": true]
        Client.shared?.send(event: event, completion: { (error) in
            
        })
    }
    
}

extension Error {
    
    func record() {
        let event = Event(level: .error)
        event.message = self.localizedDescription
        event.extra = ["ios": true]
        Client.shared?.send(event: event, completion: { (error) in
            
        })

    }

}

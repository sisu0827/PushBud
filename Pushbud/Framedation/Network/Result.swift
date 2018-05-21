//
//  APIClient.swift
//
//  Copyright © 2017 Martoff. All rights reserved.
//

import Foundation

enum Result<Value, String> {
    case Success(Value)
    case Failure(String)

    var isSuccess: Bool {
        switch self {
        case .Success:
            return true
        case .Failure:
            return false
        }
    }

    var isFailure: Bool {
        return !isSuccess
    }

    var value: Value? {
        switch self {
        case .Success(let value):
            return value
        case .Failure:
            return nil
        }
    }

    var error: String? {
        switch self {
        case .Success:
            return nil
        case .Failure(let error):
            return error
        }
    }
}

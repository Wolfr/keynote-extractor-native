//
//  Result.swift
//  KeynoteExtractor
//
//  Created by David Sinclair on 2016-10-23.
//

import Foundation

public enum Result<Value> {
    case success(Value)
    case failure(Error)
    
    /// Initializer for a success with `value`.
    ///
    /// - Parameter value: The success value.
    public init(value: Value) {
        self = .success(value)
    }
    
    /// Initializer for a failure with `error`.
    ///
    /// - Parameter error: The error.
    public init(error: Error) {
        self = .failure(error)
    }
    
    /// Returns `true` if the result is a success, otherwise `false`.
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    /// Returns `true` if the result is a failure, otherwise `false`.
    public var isFailure: Bool {
        return !isSuccess
    }
    
    /// Returns the associated value if the result is a success, otherwise `nil`.
    public var value: Value? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    /// Returns the associated error if the result is a failure, otherwise `nil`.
    public var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}


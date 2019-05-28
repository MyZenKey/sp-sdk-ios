//
//  Result.swift
//  AppAuth
//
//  Created by Adam Tierney on 2/26/19.
//

import Foundation

enum Result<T, E: Error> {
    case value(T)
    case error(E)
}

extension Result {
    func flatMap<NewValue>(_ transform: (T) throws -> Result<NewValue, E>) rethrows -> Result<NewValue, E> {
        switch self {
        case .value(let value):
            return try transform(value)
        case .error(let error):
            return Result<NewValue, E>.error(error)
        }
    }
}
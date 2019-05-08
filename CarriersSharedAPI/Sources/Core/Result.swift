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

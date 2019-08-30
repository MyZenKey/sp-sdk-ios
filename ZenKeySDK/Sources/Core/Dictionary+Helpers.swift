//
//  Dictionary+Helpers.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 7/25/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

extension Dictionary where Value: Any {
    subscript<T>(_ key: Key, or `default`: @autoclosure () -> T) -> T {
        if let value = self[key] as? T {
            return value
        }
        return `default`()
    }
}

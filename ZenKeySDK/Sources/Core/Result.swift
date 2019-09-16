//
//  Result.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/26/19.
//  Copyright © 2019 XCI JV, LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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

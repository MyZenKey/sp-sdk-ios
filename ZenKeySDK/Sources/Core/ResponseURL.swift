//
//  ResponseURL.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 4/18/19.
//  Copyright © 2019-2020 ZenKey, LLC.
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

enum URLResponseError: Error {
    case stateMismatch
    case missingParameter(String)
    case errorResponse(String, String?)
}

struct ResponseURL {
    private enum Keys: String {
        case state
    }

    private let queryDictionary: [String: String]
    init(url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        // duplicate keys are unsupported, let's reduce to a dictionary:
        queryDictionary = (components?.queryItems ?? [])
            .reduce([:]) { accumulator, item in
                var accumulator = accumulator
                if let value = item.value {
                    accumulator[item.name] = value
                }
                return accumulator
        }
    }

    subscript (param: String) -> String? {
        return queryDictionary[param]
    }

    /// Checks the redirect url for an open id 'state' value and returns successfully
    /// if it matches the value provided.
    ///
    /// - Parameter state: the state value to attempt to match.
    /// - Returns: a successful result or an error if the url state doesn't match the value
    /// provided.
    func hasMatchingState(_ state: String?) -> Result<Void, URLResponseError> {
        guard
            let inboundState = queryDictionary[Keys.state.rawValue],
            inboundState == state else {
                return .failure(URLResponseError.stateMismatch)
        }

        return .success(())
    }

    func getRequiredValue(_ param: String) -> Result<String, URLResponseError> {
        guard let value = self[param] else {
            return .failure(URLResponseError.missingParameter(param))
        }
        return .success(value)
    }
}

// MARK: - URL Error

/// adds support for extracting errors from the response url:
/// checks for errors using the OAuth error response as per RFC6749 Section 4.1.2.1
extension ResponseURL {

    private enum ErrorKeys: String {
        case error
        case errorDescription = "error_description"
    }

    func getError() -> Result<Void, URLResponseError> {
        let errorCode = self[ErrorKeys.error.rawValue]
        guard errorCode == nil else {
            let errorCode = errorCode!
            let errorDescription = self[ErrorKeys.errorDescription.rawValue]
            return .failure(URLResponseError.errorResponse(errorCode, errorDescription))
        }
        return .success(())
    }
}

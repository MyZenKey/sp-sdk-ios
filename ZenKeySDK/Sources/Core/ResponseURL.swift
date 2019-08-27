//
//  ResponseURL.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 4/18/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
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
                return .error(URLResponseError.stateMismatch)
        }

        return .value(())
    }

    func getRequiredValue(_ param: String) -> Result<String, URLResponseError> {
        guard let value = self[param] else {
            return .error(URLResponseError.missingParameter(param))
        }
        return .value(value)
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
            return .error(URLResponseError.errorResponse(errorCode, errorDescription))
        }
        return .value(())
    }
}

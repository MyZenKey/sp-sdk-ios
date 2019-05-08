//
//  ResponseURL.swift
//  CarriersSharedAPI
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

    /// Checks the redirect url for an open id 'state' value and returns true
    /// if it matches the value provided.
    ///
    /// - Parameter state: the state value to attempt to match.
    /// - Returns: whether the url contains a state paramter matching the provided value
    func assertMatchingState(_ state: String) throws {
        guard
            let inboundState = queryDictionary[Keys.state.rawValue],
            inboundState == state else {
                throw URLResponseError.stateMismatch
        }
    }

    func getRequiredValue(_ param: String) throws -> String {
        guard let value = self[param] else {
            throw URLResponseError.missingParameter(param)
        }
        return value
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

    func assertSuccess() throws {
        let errorCode = self[ErrorKeys.error.rawValue]
        guard errorCode == nil else {
            let errorCode = errorCode!
            let errorDescription = self[ErrorKeys.errorDescription.rawValue]
            throw URLResponseError.errorResponse(errorCode, errorDescription)
        }
    }
}

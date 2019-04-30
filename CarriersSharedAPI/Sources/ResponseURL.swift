//
//  ResponseURL.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 4/18/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

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
    func hasMatchingState(_ state: String) -> Bool {
        guard
            let inboundState = queryDictionary[Keys.state.rawValue],
            inboundState == state else {
                return false
        }
        return true
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

    var error: Error? {
        let errorId = self[ErrorKeys.error.rawValue]
        guard errorId == nil else {
            let errorId = errorId!
            let errorDescription = self[ErrorKeys.errorDescription.rawValue]
            let error = ResponseURL.errorValue(
                fromIdentifier: errorId,
                description: errorDescription
            )
            return error
        }

        return nil
    }

    // TODO: - only expose subset of these errors
    static func errorValue(
        fromIdentifier identifier: String,
        description: String?) -> AuthorizationError {

        if let errorCode = OAuthErrorCode(rawValue: identifier) {
            return .oauth(errorCode, description)
        } else if let errorCode = OpenIdErrorCode(rawValue: identifier) {
            return .openId(errorCode, description)
        } else if let errorCode = ProjectVerifyErrorCode(rawValue: identifier) {
            return .projectVerify(errorCode, description)
        }
        return .unknown(identifier, description)
    }
}

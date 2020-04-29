//
//  AuthorizationError.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/27/19.
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

/// An error type which encapsulates the errors that can occur during the authorization flow.
public struct AuthorizationError: Error, Equatable {
    /// An error occuring during the OpenId Authorization flow.
    public enum ErrorType: Equatable {
        /// The request made is invalid. Check the parameters passed to the authorization call.
        case invalidRequest
        /// The request was denied by the user or carrier.
        case requestDenied
        /// The request has timed out.
        case requestTimeout
        /// There was an error on the server. Please try again later.
        case serverError
        /// There was a problem communicating over the network. Check your connection and try again.
        case networkFailure
        /// There is an error configuring the SDK. Confirm your configuration locally and with the
        /// service provider portal.
        case configurationError
        /// There is an inconsistency with the user's state. Retry discovery.
        case discoveryStateError
        /// An unknown error has occured. If the problem persists, contact support.
        case unknownError
    }

    /// The error's code. This will provide context as to the origin of the error.
    ///
    /// - SeeAlso: `ErrorCodes.swift`
    public let code: String
    /// A description of the error if any.
    public let description: String?
    /// The error type dictates potential origin and recovery suggestion.
    public let errorType: ErrorType

    init(rawErrorCode code: String,
         description: String? = nil) {
        self.code = code
        self.description = description

        if let knownErrorCode = code.knownAuthorizationErrorCode {
            self.errorType = knownErrorCode.errorType
        } else {
            self.errorType = .unknownError
        }
    }
}

extension AuthorizationError {
    static var unknownAuthorizationError: AuthorizationError {
        return AuthorizationError(
            rawErrorCode: "unknown_error",
            description: "an unexpected error has occured."
        )
    }
}

/// An error value which corresponds with an `AuthorizationError.ErrorType`
protocol AuthorizationErrorTypeMappable {
    var errorType: AuthorizationError.ErrorType { get }
}

/// An error value which can be parsed into an `AuthorizationError`
protocol AuthorizationErrorConvertible {
    var asAuthorizationError: AuthorizationError { get }
}

// MARK: - Auth Error Conformance

extension URLResponseError: AuthorizationErrorConvertible {
    var description: String? {
        switch self {
        case .stateMismatch:
            return "the state returned did not match the state sent"
        case .missingParameter(let param):
            return "the paramter '\(param)' is required"
        case .errorResponse(_, let description):
            return description
        }
    }

    var errorCode: String {
        switch self {
        case .stateMismatch:
            return SDKErrorCode.stateMismatch.rawValue
        case .missingParameter:
            return SDKErrorCode.missingParameter.rawValue
        case .errorResponse(let code, _):
            return code
        }
    }

    var asAuthorizationError: AuthorizationError {
        return AuthorizationError(
            rawErrorCode: errorCode,
            description: description
        )
    }
}

extension RequestStateError: AuthorizationErrorConvertible {
    var asAuthorizationError: AuthorizationError {
        return AuthorizationError(
            rawErrorCode: "state_generation_error",
            description: "Unable to generate a state parameter. Please try again."
        )
    }
}

extension DiscoveryServiceError: AuthorizationErrorConvertible {
    var asAuthorizationError: AuthorizationError {
        switch self {
        case .issuerError(let issuerError):
            return AuthorizationError(
                rawErrorCode: issuerError.error,
                description: issuerError.errorDescription
            )

        case .networkError:
            return AuthorizationError(
                rawErrorCode: SDKErrorCode.networkError.rawValue,
                description: "a network error occurred"
            )
        }
    }
}

extension OpenIdServiceError: AuthorizationErrorConvertible {
    var asAuthorizationError: AuthorizationError {
        switch self {
        case .viewControllerNotInHeirarchy:
            return AuthorizationError.ConfigErrors.viewControllerNotInHeirarchy
        case .urlResolverError:
            return AuthorizationError(
                rawErrorCode: SDKErrorCode.networkError.rawValue,
                description: "a network error occurred"
            )
        case .urlResponseError(let urlError):
            return urlError.asAuthorizationError
        }
    }
}

extension MobileNetworkSelectionError: AuthorizationErrorConvertible {
    var asAuthorizationError: AuthorizationError {
        switch self {
        case .viewControllerNotInHeirarchy:
            return AuthorizationError.ConfigErrors.viewControllerNotInHeirarchy
        case .invalidMCCMNC:
            return AuthorizationError(
                rawErrorCode: SDKErrorCode.invalidParameter.rawValue,
                description: "mccmnc paramter is misformatted"
            )
        case .urlResponseError(let urlError):
            return urlError.asAuthorizationError

        case .stateError(let stateError):
            return stateError.asAuthorizationError
        }
    }
}

extension AuthorizationStateMachineError: AuthorizationErrorConvertible {
    var asAuthorizationError: AuthorizationError {
        switch self {
        case .tooManyRedirects:
            return AuthorizationError(
                rawErrorCode: SDKErrorCode.tooManyUIRedirects.rawValue,
                description: "Discovery redirected to ui too many times. Please retry discovery"
            )
        case .tooManyRecoveries:
            return AuthorizationError(
                rawErrorCode: ZenKeyErrorCode.userNotFound.rawValue,
                description: "Discovery was unable to recover from a user not found error. Please retry discovery"
            )
        }
    }
}

extension AuthorizationError {
    struct ConfigErrors {
        static let viewControllerNotInHeirarchy = AuthorizationError(
            rawErrorCode: SDKErrorCode.invalidParameter.rawValue,
            description: "ensure you're presenting on a valid view controller"
        )
    }
}

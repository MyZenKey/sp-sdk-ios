//
//  AuthorizationError.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/27/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

public struct AuthorizationError: Error, Equatable {
    /// An error occuring during the Open Id Authorization flow
    public enum ErrorType: Equatable {
        case invalidRequest
        case requestDenied
        case requestTimeout
        case serverError
        case networkFailure
        case configurationError
        case discoveryStateError
        case unknownError
    }

    public let errorType: ErrorType
    public let code: String
    public let description: String?

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

/// An error value which corresponds with an AuthorizationError.ErrorType
protocol AuthorizationErrorTypeMappable {
    var errorType: AuthorizationError.ErrorType { get }
}

/// An error value which can be parsed into an AuthorizationError
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
        case .invalidMCCMNC:
            return AuthorizationError(
                rawErrorCode: SDKErrorCode.invalidParameter.rawValue,
                description: "mccmnc paramter is misformatted"
            )
        case .urlResponseError(let urlError):
            return urlError.asAuthorizationError
        }
    }
}

//
//  ErrorCodes.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 3/11/19.
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

/// OAuth 2.0 Error Codes
///
/// for additional info, see: [OAuth 2.0 Authorization Section 4.2.2.1](https://tools.ietf.org/html/rfc6749#page-35)
public enum OAuthErrorCode: String {
    /// The service provider has constructed a bad request. This may be due to any of the parameters
    /// submitted. The service provider should visit the service portal to confirm the parameters
    /// they should use.
    case invalidRequest = "invalid_request"
    /// The service provider has constructed a bad request. This may be due to any of the parameters
    /// submitted. The service provider should visit the service portal to confirm the parameters
    /// they should use.
    case unauthorizedClient = "unauthorized_client"
    /// The service provider has constructed a bad request. This may be due to any of the parameters
    /// submitted. The service provider should only use code or async-token.
    case unsupportedResponseType = "unsupported_response_type"
    /// The service provider has constructed a bad request.
    /// The service provider should visit the
    /// service portal to confirm the scopes allowed.
    case invalidScope = "invalid_scope"
    /// There is a problem with the ZenKey solution or application.
    /// An SP may assume that a retry at a later time may be successful.
    case temporarilyUnavailable = "temporarily_unavailable"
    /// The resource owner or authorization server denied the request.
    ///
    /// - SeeAlso: `ZenKeyErrorCode.requestDenied`
    case accessDenied = "access_denied"
}

extension OAuthErrorCode: AuthorizationErrorTypeMappable {
    var errorType: AuthorizationError.ErrorType {
        switch self {
        case .invalidRequest, .unauthorizedClient:
            return .configurationError
        case .accessDenied:
            return .requestDenied
        case .unsupportedResponseType:
            return .unknownError
        case .invalidScope:
            return .invalidRequest
        case .temporarilyUnavailable:
            return .serverError
        }
    }
}

/// Open Id Error Codes
///
/// for additional info, see:
/// [OpenId Connect Core Section 3.1.2.6](https://openid.net/specs/openid-connect-core-1_0.html#AuthError)
public enum OpenIdErrorCode: String {
    /// The service provider should not be using `display=none`.
    case interactionRequired = "interaction_required"
    /// The service provider should not be using `display=none`.
    case loginRequired = "login_required"
    case invalidRequestURI = "invalid_request_uri"
    /// This error may be returned while carriers are still adding support for Request objects.
    case invalidRequestObject = "invalid_request_object"
    /// This error may be returned while carriers are still adding support for Request objects.
    case requestNotSupported = "request_not_supported"
    /// Request URI’s won’t be supported.
    case requestURINotSupported = "request_uri_not_supported"
    /// Dynamic registration will not be supported.
    case registrationNotSupported = "registration_not_supported"
    /// This error should never be returned in the context of ZenKey.
    case accountSelectionRequired = "account_selection_required"
    /// This error should never be returned in the context of ZenKey.
    case consentRequired = "consent_required"
}

extension OpenIdErrorCode: AuthorizationErrorTypeMappable {
    var errorType: AuthorizationError.ErrorType {
        switch self {
        case .invalidRequestObject:
            return .invalidRequest
        case .interactionRequired, .loginRequired, .accountSelectionRequired, .consentRequired,
             .invalidRequestURI, .requestNotSupported,
             .requestURINotSupported, .registrationNotSupported:
            return .unknownError
        }
    }
}

/// ZenKey Error Codes
public enum ZenKeyErrorCode: String {
    /// This may be returned if the carrier does not support the user identity. (This may be that
    /// the phone number is not currently on this carrier, or that the subscriber ID is for a user
    /// that has ported out).
    ///
    /// The service provider should re-try discovery to locate this user.
    case userNotFound = "user_not_found"
    /// The user may not have access to their phone and therefore the transaction may have failed.
    /// Or the user did not notice the request.
    case authenticationTimedOut = "authentication_timed_out"
    /// The user's device has been unsuccessful with authentication. This may happen if the user has
    /// changed SIM cards, or just reset their device.
    case networkFailure = "network_failure"
    /// A Server initiated request has been unavailable to be delivered to the
    /// device. (state:!=delivered)
    /// Note: this may occure after the carrier has been unable retrying a push message
    /// to a device <x> times. Over <x> min.
    case deviceUnavailable = "device_unavailable"
    /// A user that does not have the CCID application, and or has decided not to install the CCID
    /// application. This error is likely on server initiated responses where the user does not have
    /// the app. Or may accur if the user had CCID but then changed devices, or uninstalled the app.
    case userUnsupported = "user_unsupported"
    /// The login hint token returned by discovery ui is not valid for this user on this carrier.
    case invalidLoginHint = "invalid_login_hint"
    /// Formatting is incorrect. SP should try to use an extracted sub as login_hint.
    case invalidLoginHintToken = "invalid_login_hint_token"
}

extension ZenKeyErrorCode: AuthorizationErrorTypeMappable {
    var errorType: AuthorizationError.ErrorType {
        switch self {
        case .deviceUnavailable:
            return .requestDenied
        case .networkFailure:
            return .networkFailure
        case .authenticationTimedOut:
            return .requestTimeout
        case .userNotFound, .userUnsupported, .invalidLoginHint, .invalidLoginHintToken:
            return .discoveryStateError
        }
    }
}

/// Error codes for errors occuring locally to the SDK.
public enum SDKErrorCode: String {
    /// The SDK received a network error when communicating with an endpoint.
    case networkError = "sdk_network_error"
    /// The SDK received a url with a state which did not match the request.
    case stateMismatch = "sdk_mismatch_state"
    /// The SDK received a response which was missing a required parameter.
    case missingParameter = "sdk_missing_parameter"
    /// The SDK received a response with a parameter which did not pass validation.
    case invalidParameter = "sdk_invalid_parameter"
    /// The SDK has been redirected to the discovery-ui too many times.
    case tooManyUIRedirects = "sdk_too_many_redirects"
}

extension SDKErrorCode: AuthorizationErrorTypeMappable {
    var errorType: AuthorizationError.ErrorType {
        switch self {
        case .stateMismatch, .missingParameter, .invalidParameter:
            return .unknownError
        case .tooManyUIRedirects:
            return .discoveryStateError
        case .networkError:
            return .networkFailure
        }
    }
}

extension String {
    /// - Returns: a typed version of the known error code string.
    var knownAuthorizationErrorCode: AuthorizationErrorTypeMappable? {
        let errorCodes: [(String) -> AuthorizationErrorTypeMappable?] = [
            OAuthErrorCode.init,
            OpenIdErrorCode.init,
            ZenKeyErrorCode.init,
            SDKErrorCode.init,
        ]
        return errorCodes.compactMap({ $0(self) }).first
    }
}

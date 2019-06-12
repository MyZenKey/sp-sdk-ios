//
//  ErrorCodes.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 3/11/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
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
    /// The service provider has constructed a bad request. The service provider should visit the
    /// service portal to confirm the
    /// scopes allowed.
    case invalidScope = "invalid_scope"
    case serverError = "server_error"
    case temporarilyUnavailable = "temporarily_unavailable"
    /// The resource owner or authorization server denied the request.
    ///
    /// - SeeAlso: `ProjectVerifyErrorCode.requestDenied`
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
        case .serverError, .temporarilyUnavailable:
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
    case requestUIRNotSupported = "request_uri_not_supported"
    /// Dynamic registration will not be supported.
    case registrationNotSupported = "registration_not_supported"
    /// This error should never be returned in the context of project verify.
    case accountSelectionRequired = "account_selection_required"
    /// This error should never be returned in the context of project verify.
    case consentRequired = "consent_required"
}

extension OpenIdErrorCode: AuthorizationErrorTypeMappable {
    var errorType: AuthorizationError.ErrorType {
        switch self {
        case .invalidRequestObject:
            return .invalidRequest
        case .interactionRequired, .loginRequired, .accountSelectionRequired, .consentRequired,
             .invalidRequestURI, .requestNotSupported,
             .requestUIRNotSupported, .registrationNotSupported:
            return .unknownError
        }
    }
}

/// Project Verify Error Codes
public enum ProjectVerifyErrorCode: String {
    /// This may be returned if the carrier does not support the user identity. (This may be that
    /// the phone number is not currently on this carrier, or that the subscriber ID is for a user
    /// that has ported out).
    ///
    /// The service provider should re-try discovery to locate this user.
    case userNotFound = "user_not_found"
    /// The user has denied the transaction.
    case requestDenied = "request_denied"
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
    /// In the event device authentication has failed.
    case deviceAuthenticationFailure = "device_authentication_failure"
    /// A user that does not have the CCID application, and or has decided not to install the CCID
    /// application. This error is likely on server initiated responses where the user does not have
    /// the app. Or may accur if the user had CCID but then changed devices, or uninstalled the app.
    case userUnsupported = "user_unsupported"
    /// The login hint token returned by discovery ui is not valid for this user on this carrier.
    case invalidLoginHint = "invalid_login_hint"
}

extension ProjectVerifyErrorCode: AuthorizationErrorTypeMappable {
    var errorType: AuthorizationError.ErrorType {
        switch self {
        case .requestDenied, .deviceUnavailable, .deviceAuthenticationFailure:
            return .requestDenied
        case .networkFailure:
            return .networkFailure
        case .authenticationTimedOut:
            return .requestTimeout
        case .userNotFound, .userUnsupported, .invalidLoginHint:
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
            ProjectVerifyErrorCode.init,
            SDKErrorCode.init,
        ]
        return errorCodes.compactMap({ $0(self) }).first
    }
}

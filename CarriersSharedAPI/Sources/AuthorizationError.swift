//
//  AuthorizationError.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 3/11/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

/// An error occuring during the Open Id Authorization flow
public enum AuthorizationError: Error {
    case stateMismatch
    case missingAuthCode
    case oauth(OAuthErrorCode, String?)
    case openId(OpenIdErrorCode, String?)
    case projectVerify(ProjectVerifyErrorCode, String?)
    case unknown(String, String?)
}

/// OAuth 2.0 Error Codes
///
/// for additional info, see: [OAuth 2.0 Authorization Section 4.2.2.1](https://tools.ietf.org/html/rfc6749#page-35)
public enum OAuthErrorCode: String {
    /// The RP has constructed a bad request. This may be due to any of the parameters submitted.
    /// The RP should visit the service portal to confirm the parameters they should use.
    case invalidRequest = "invalid_request"
    /// The RP has constructed a bad request. This may be due to any of the parameters submitted.
    /// The RP should visit the service portal to confirm the parameters they should use.
    case unauthorizedClient = "unauthorized_client"
    /// The RP has constructed a bad request. This may be due to any of the parameters submitted.
    /// The RP should only use code or async-token.
    case unsupportedResponseType = "unsupported_response_type"
    /// The RP has constructed a bad request. The RP should visit the service portal to confirm the
    /// scopes allowed
    case invalidScope = "invalid_scope"
    case serverError = "server_error"
    case temporarilyUnavailable = "temporarily_unavailable"
    /// The resource owner or authorization server denied the request.
    ///
    /// - SeeAlso: `ProjectVerifyErrorCode.requestDenied`
    case accessDenied = "access_denied"
}

/// Open Id Error Codes
///
/// for additional info, see [OpenId Connect Core Section 3.1.2.6](https://openid.net/specs/openid-connect-core-1_0.html#AuthError)
public enum OpenIdErrorCode: String {
    /// The RP should not be using `display=none`
    case interactionRequired = "interaction_required"
    /// The RP should not be using `display=none`
    case loginRequired = "login_required"
    case invalidRequestURI = "invalid_request_uri"
    /// This error may be returned while carriers are still adding support for Request objects
    case invalidRequestObject = "invalid_request_object"
    /// This error may be returned while carriers are still adding support for Request objects
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

/// Project Verify Error Codes
public enum ProjectVerifyErrorCode: String {
    /// This may be returned if the carrier does not support the user identity. (this may be that
    /// the phone number is not currently on this carrier, or that the subscriber ID is for a user
    /// that has ported out).
    ///
    /// The RP should re-try discovery to locate this user.
    case userNotFound = "user_not_found"
    /// The user has denied the transaction.
    case requestDenied = "request_denied"
    /// The user may not have access to their phone and therefore the  transaction may have failed.
    /// Or the user did not notice the request.
    case authenticationTimedOut = "authentication_timed_out"
    /// The user's device has been unsuccessful with authentication. This may happen if the user has
    /// changed SIM cards, or just reset their device.
    case networkFailure = "network_failure"
}

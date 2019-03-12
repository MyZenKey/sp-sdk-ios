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
public enum OAuthErrorCode: String {
    /// The RP has constructed a bad request. This may be due to any of the parameters submitted.
    /// The RP should visit the service portal to confirm the parameters they should use.
    case invalidRequest = "invalid_request"
    /// The RP has constructed a bad request. This may be due to any of the parameters submitted.
    /// The RP should visit the service portal to confirm the parameters they should use.
    case unauthorizedClient = "unauthorized_client"
    /// The RP has constructed a bad request. This may be due to any of the parameters submitted.
    /// The RP should only use code or async-token.
    case unsupportedResponseType = "unsupported_responce_type"
    /// The RP has constructed a bad request. The RP should visit the service portal to confirm the
    /// scopes allowed
    case invalidScope = "invalid_scope"
    case serverError = "server_error"
    case temporarilyUnavailable = "temporarily_unavailable"
}

/// Open Id Error Codes
public enum OpenIdErrorCode: String {
    /// The RP should not be using display=none
    case interactionRequired = "interaction_required"
    /// The RP should not be using display=none
    case loginRequired = "login_required"
    /// This error should never be returned.
    case accountSelectionRequired = "account_selection_required"
    /// This error should never be returned.
    case consentRequired = "consent_required"
    case invalidRequestURI = "invalid_request_uri"
    /// This error may be returned while carriers are still adding support for Request objects
    case invalidRequestObject = "invalid_request_object"
    /// This error may be returned while carriers are still adding support for Request objects
    case requestNotSupported = "request_not_supported"
    /// Request URI’s won’t be supported.
    case requestUIRNotSupported = "request_uri_not_supported"
    /// Dynamic registration will not be supported.
    case registrationNotSupported = "registration_not_supported"
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
    /// The users device has been unsuccessful with authentication. This may happen if the user has
    /// changed sim cards, or just reset their device.
    case networkFailure = "network_failure"
}

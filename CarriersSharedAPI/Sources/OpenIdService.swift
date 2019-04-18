//
//  OpenIdService.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/27/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
import AppAuth

enum ResponseType: String {
    case code = "code"
}

public struct UnsupportedCarrier: Error { }

/// Represents the successful compltion of an autorization request. The code should be used to
/// retrieve a token from a secure server.
public struct AuthorizedResponse: Equatable {
    /// Authorization code returned from the issuer.
    public let code: String
    /// The Mobile Country Code used to identify the correct issuer.
    public let mcc: String
    /// The Mobile Network Code used to identify the correct issuer.
    public let mnc: String
}

/// The outcome of an Authorization Operation.
public enum AuthorizationResult {
    /// A successful authorization returns the authorization code and mcc/mnc corresponding to the
    /// issuer used to return the authorized code.
    case code(AuthorizedResponse)
    /// When an error occurs it is surfaced here with this result.
    case error(Error)
    /// When the authorizaiton is cancelled this result is returned.
    case cancelled
}

public typealias AuthorizationCompletion = (AuthorizationResult) -> Void

struct OpenIdAuthorizationConfig: Equatable {
    let simInfo: SIMInfo
    let clientId: String
    let authorizationEndpoint: URL
    let tokenEndpoint: URL
    let formattedScopes: String
    let redirectURL: URL
    let state: String
}

protocol OpenIdServiceProtocol {
    func authorize(
        fromViewController viewController: UIViewController,
        authorizationConfig: OpenIdAuthorizationConfig,
        completion: @escaping AuthorizationCompletion
    )

    var authorizationInProgress: Bool { get }

    func cancelCurrentAuthorizationSession()

    func conclude(withURL url: URL)
}

class PendingSessionStorage: OpenIdExternalSessionStateStorage {
    var pendingSession: OIDExternalUserAgentSession?
}

class OpenIdService {
    enum ResponseKeys: String {
        case state
        case code
    }

    enum State {
        case idle
        case inProgress(OIDAuthorizationRequest, SIMInfo, AuthorizationCompletion, PendingSessionStorage)
    }

    var state: State = .idle

    var authorizationInProgress: Bool {
        switch state {
        case .idle:
            return false
        case .inProgress:
            return true
        }
    }

    let urlResolver: OpenIdURLResolverProtocol

    init(urlResolver: OpenIdURLResolverProtocol) {
        self.urlResolver = urlResolver
    }
}

extension OpenIdService: OpenIdServiceProtocol {
    func authorize(
        fromViewController viewController: UIViewController,
        authorizationConfig: OpenIdAuthorizationConfig,
        completion: @escaping AuthorizationCompletion
        ) {

        // issuing a second authorization flow causes the first to be cancelled:
        if case .inProgress = state {
            cancelCurrentAuthorizationSession()
        }
        
        let openIdConfiguration = OIDServiceConfiguration(
            authorizationEndpoint: authorizationConfig.authorizationEndpoint,
            tokenEndpoint: authorizationConfig.tokenEndpoint
        )

        //create the authorization request
        let authorizationRequest: OIDAuthorizationRequest = OpenIdService.createAuthorizationRequest(
            openIdServiceConfiguration: openIdConfiguration,
            authorizationConfig: authorizationConfig
        )

        let sessionStorage = PendingSessionStorage()
        
        let simInfo = authorizationConfig.simInfo
        urlResolver.resolve(
            request: authorizationRequest,
            usingStorage: sessionStorage,
            fromViewController: viewController,
            authorizationConfig: authorizationConfig) { [weak self] (authState, error) in
                guard
                    error == nil,
                    let authState = authState,
                    let authCode = authState.lastAuthorizationResponse.authorizationCode else {
                        self?.concludeAuthorizationFlow(result: .error(error ?? UnknownError()))
                        return
                }

                let authorizedResponse = AuthorizedResponse(
                    code: authCode,
                    mcc: simInfo.mcc,
                    mnc: simInfo.mnc
                )

                self?.concludeAuthorizationFlow(result: .code(authorizedResponse))
        }

        state = .inProgress(authorizationRequest, simInfo, completion, sessionStorage)
    }
    
    func cancelCurrentAuthorizationSession() {
        concludeAuthorizationFlow(result: .cancelled)
    }

    func conclude(withURL url: URL) {
        // NOTE: this logic replicates the functionality in OIDAuthorizationService.m
        // - (BOOL)resumeExternalUserAgentFlowWithURL:(NSURL *)URL
        // Because AppAuth is designed around the OAuth 2.0 spec for native apps
        // (https://tools.ietf.org/html/rfc8252)
        // it is designed for apps implementing a public client authorization+token flow
        // we would use the above is the method if we wanted to also request a token but it
        // doen't support only requesting authorization. Here we'll short circut the token flow and
        // hand that off to the SP:

        // ensure valid state:
        guard case .inProgress(let request, let simInfo, _, _) = state else {
            // there is no request, return
            return
        }

        let response = ResponseURL(url: url)

        let error = response.openIdError
        guard error == nil else {
            concludeAuthorizationFlow(result: .error(error!))
            return
        }

        // no error, should be a valid OAuth 2.0 response
        guard
            let state = request.state,
            response.hasMatchingState(state)
            else {
                concludeAuthorizationFlow(result: .error(AuthorizationError.stateMismatch))
                return
        }

        // extract the code
        guard let code = response[ResponseKeys.code.rawValue] else {
            concludeAuthorizationFlow(result: .error(AuthorizationError.missingAuthCode))
            return
        }

        // success:
        concludeAuthorizationFlow(result: .code(
            AuthorizedResponse(code: code, mcc: simInfo.mcc, mnc: simInfo.mnc)
            )
        )
    }

    func concludeAuthorizationFlow(result: AuthorizationResult) {
        defer {
            state = .idle
        }

        guard case .inProgress(_, _, let completion, _) = state else {
            return
        }

        completion(result)
    }
}

extension OpenIdService {
    
    static func createAuthorizationRequest(
        openIdServiceConfiguration: OIDServiceConfiguration,
        authorizationConfig: OpenIdAuthorizationConfig) -> OIDAuthorizationRequest {
        
        let request: OIDAuthorizationRequest = OIDAuthorizationRequest(
            configuration: openIdServiceConfiguration,
            clientId: authorizationConfig.clientId,
            clientSecret: nil,
            scope: authorizationConfig.formattedScopes,
            redirectURL: authorizationConfig.redirectURL,
            responseType: ResponseType.code.rawValue,
            state: authorizationConfig.state,
            nonce: nil,
            codeVerifier: nil,
            codeChallenge: nil,
            codeChallengeMethod: nil,
            additionalParameters: nil
        )
        
        return request
    }
}

// MARK: - permanent home

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

extension ResponseURL {

    enum OpenIdErrorKeys: String {
        case error
        case errorDescription = "error_description"
    }

    var openIdError: Error? {
        // checks for an OAuth error response as per RFC6749 Section 4.1.2.1
        let errorId = self[OpenIdErrorKeys.error.rawValue]
        guard errorId == nil else {
            let errorId = errorId!
            let errorDescription = self[OpenIdErrorKeys.errorDescription.rawValue]
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

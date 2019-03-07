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

public struct AuthorizedResponse {
    public let code: String
    public let mcc: String
    public let mnc: String
}

public enum AuthorizationResult {
    case code(AuthorizedResponse)
    case error(Error)
    case cancelled
}

public typealias AuthorizationCompletion = (AuthorizationResult) -> Void

public enum OpenIdError: Error {
    case stateMismatch
    case missingAuthCode
}

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
        authorizationConifg: OpenIdAuthorizationConfig,
        completion: @escaping AuthorizationCompletion
    )

    var authorizationInProgress: Bool { get }

    func cancelCurrentAuthorizationSession()

    func concludeAuthorizationFlow(url: URL)
}

class OpenIdService {
    enum ResponseKeys: String {
        case state
        case code
        case error
        case errorDescription = "error_description"
    }

    enum State {
        case idle
        case inProgress(OIDAuthorizationRequest, SIMInfo, AuthorizationCompletion)
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
        authorizationConifg: OpenIdAuthorizationConfig,
        completion: @escaping AuthorizationCompletion
        ) {

        let openIdConfiguration = OIDServiceConfiguration(
            authorizationEndpoint: authorizationConifg.authorizationEndpoint,
            tokenEndpoint: authorizationConifg.tokenEndpoint
        )

        //create the authorization request
        let authorizationRequest: OIDAuthorizationRequest = self.createAuthorizationRequest(
            openIdServiceConfiguration: openIdConfiguration,
            authorizationConifg: authorizationConifg
        )

        let simInfo = authorizationConifg.simInfo
        urlResolver.resolve(
            withRequest: authorizationRequest,
            fromViewController: viewController,
            authorizationConfig: authorizationConifg) { [weak self] (authState, error) in
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

        state = .inProgress(authorizationRequest, simInfo, completion)
    }

    func createAuthorizationRequest(
        openIdServiceConfiguration: OIDServiceConfiguration,
        authorizationConifg: OpenIdAuthorizationConfig) -> OIDAuthorizationRequest {

        let request: OIDAuthorizationRequest = OIDAuthorizationRequest(
            configuration: openIdServiceConfiguration,
            clientId: authorizationConifg.clientId,
            clientSecret: nil,
            scope: authorizationConifg.formattedScopes,
            redirectURL: authorizationConifg.redirectURL,
            responseType: ResponseType.code.rawValue,
            state: authorizationConifg.state,
            nonce: nil,
            codeVerifier: nil,
            codeChallenge: nil,
            codeChallengeMethod: nil,
            additionalParameters: nil
        )

        return request
    }

    func cancelCurrentAuthorizationSession() {
        concludeAuthorizationFlow(result: .cancelled)
    }

    func concludeAuthorizationFlow(url: URL) {

        // NOTE: this logic replicates the functionality in OIDAuthorizationService.m
        // - (BOOL)resumeExternalUserAgentFlowWithURL:(NSURL *)URL
        // the above is the method we would use but it goes directly into the token flow
        // as this is treated as one flow by AppAuth. Here we'll short circut the token flow and
        // hand that off to the SP:

        // ensure valid state:
        guard case .inProgress(let request, let simInfo, _) = state else {
            // there is no request, return
            return
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        // duplicate keys are unsupported, let's reduce to a dictionary:
        let queryDictionary: [String: String] = (components?.queryItems ?? [])
            .reduce([:]) { accumulator, item in
                var accumulator = accumulator
                if let value = item.value {
                    accumulator[item.name] = value
                }
                return accumulator
        }

        // checks for an OAuth error response as per RFC6749 Section 4.1.2.1
        guard queryDictionary[ResponseKeys.error.rawValue] == nil else {
                // TODO: handle errors as specified in section 4.5 of the api spec
                concludeAuthorizationFlow(result: .error(UnknownError()))
                return
        }

        // no error, should be a valid OAuth 2.0 response
        guard
            let inboundState = queryDictionary[ResponseKeys.state.rawValue],
            inboundState == request.state else {
                concludeAuthorizationFlow(result: .error(OpenIdError.stateMismatch))
                return
        }

        // extract the code
        guard let code = queryDictionary[ResponseKeys.code.rawValue] else {
                concludeAuthorizationFlow(result: .error(OpenIdError.missingAuthCode))
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

        guard case .inProgress(_, _, let completion) = state else {
            return
        }

        completion(result)
    }
}

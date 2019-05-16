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
    case code
}

struct OpenIdAuthorizationConfig: Equatable {
    let simInfo: SIMInfo
    let clientId: String
    let authorizationEndpoint: URL
    let tokenEndpoint: URL
    let formattedScopes: String
    let redirectURL: URL
    let loginHintToken: String?
    let state: String
}

enum OpenIdServiceError: Error {
    case urlResponseError(URLResponseError)
    case urlResolverError(Error?)
}

enum OpenIdServiceResult {
    case code(AuthorizedResponse)
    case error(OpenIdServiceError)
    case cancelled
}

typealias OpenIdServiceCompletion = (OpenIdServiceResult) -> Void

protocol OpenIdServiceProtocol: URLHandling {
    func authorize(
        fromViewController viewController: UIViewController,
        authorizationConfig: OpenIdAuthorizationConfig,
        completion: @escaping OpenIdServiceCompletion
    )

    var authorizationInProgress: Bool { get }

    func cancelCurrentAuthorizationSession()
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
        case inProgress(OIDAuthorizationRequest, SIMInfo, OpenIdServiceCompletion, PendingSessionStorage)
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
        completion: @escaping OpenIdServiceCompletion
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
                        // error value is present here, or we didn't recieve a symmetrical response
                        // from the api's result
                        self?.concludeAuthorizationFlow(result: .error(.urlResolverError(error)))
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

    func resolve(url: URL) -> Bool {
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
            return false
        }

        resolve(request: request, forSIMInfo: simInfo, withURL: url)
        return true
    }

    private func resolve(
        request: OIDAuthorizationRequest,
        forSIMInfo simInfo: SIMInfo,
        withURL url: URL) {

        let response = ResponseURL(url: url)
        guard let state = request.state else {
            fatalError("no requests should be sent without a valid state")
        }

        // validate state
        let validatedCode = response.hasMatchingState(state).promoteResult()
            // check for error
            .flatMap({ response.getError().promoteResult() })
            // extract code
            .flatMap({ response.getRequiredValue(ResponseKeys.code.rawValue).promoteResult() })

        switch validatedCode {
        case .value(let code):
            concludeAuthorizationFlow(result: .code(
                AuthorizedResponse(code: code, mcc: simInfo.mcc, mnc: simInfo.mnc)
                )
            )
        case .error(let error):
            concludeAuthorizationFlow(result: .error(error))
        }
    }

    func concludeAuthorizationFlow(result: OpenIdServiceResult) {
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

        var additionalParams: [String: String] = [:]
        if let loginHintToken = authorizationConfig.loginHintToken {
            additionalParams["login_hint_token"] = loginHintToken
        }

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
            additionalParameters: additionalParams
        )

        return request
    }
}

// MARK: - Error Mapping

private extension Result where E == URLResponseError {
    func promoteResult() -> Result<T, OpenIdServiceError> {
        switch self {
        case .value(let value):
            return .value(value)
        case .error(let error):
            return .error(.urlResponseError(error))
        }
    }
}

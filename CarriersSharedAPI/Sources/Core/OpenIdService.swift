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

struct OpenIdAuthorizationParameters: Equatable {
    let clientId: String
    let redirectURL: URL
    let formattedScopes: String
    let state: String?
    let nonce: String?

    let acrValues: [ACRValue]?
    let prompt: PromptValue?
    let correlationId: String?
    let context: String?
    var loginHintToken: String?

    init(clientId: String,
         redirectURL: URL,
         formattedScopes: String,
         state: String?,
         nonce: String?,
         acrValues: [ACRValue]?,
         prompt: PromptValue?,
         correlationId: String?,
         context: String?,
         loginHintToken: String?) {

        self.clientId = clientId
        self.redirectURL = redirectURL
        self.formattedScopes = formattedScopes
        self.state = state
        self.nonce = nonce
        self.acrValues = acrValues
        self.prompt = prompt
        self.correlationId = correlationId
        self.context = context
        self.loginHintToken = loginHintToken
    }

    var base64EncodedContext: String? {
        guard let context = context else {
                return nil
        }
        // utf8 will encode all for all swift strings:
        return context.data(using: .utf8)!
            .base64EncodedString()
    }
}

enum OpenIdServiceError: Error {
    case urlResponseError(URLResponseError)
    case urlResolverError(Error?)
    case stateError(RequestStateError)
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
        carrierConfig: CarrierConfig,
        authorizationParameters: OpenIdAuthorizationParameters,
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
        carrierConfig: CarrierConfig,
        authorizationParameters: OpenIdAuthorizationParameters,
        completion: @escaping OpenIdServiceCompletion
        ) {

        // issuing a second authorization flow causes the first to be cancelled:
        if case .inProgress = state {
            Log.log(.warn, "Implicitly cancelling previous request")
            cancelCurrentAuthorizationSession()
        }

        let openIdConfiguration = OIDServiceConfiguration(
            authorizationEndpoint: carrierConfig.openIdConfig.authorizationEndpoint,
            tokenEndpoint: carrierConfig.openIdConfig.tokenEndpoint
        )

        //create the authorization request
        let authorizationRequest: OIDAuthorizationRequest = OpenIdService.createAuthorizationRequest(
            openIdServiceConfiguration: openIdConfiguration,
            authorizationParameters: authorizationParameters
        )

        let sessionStorage = PendingSessionStorage()

        let simInfo = carrierConfig.simInfo

        Log.log(.info, "Performing auth request \(authorizationRequest)")
        urlResolver.resolve(
            request: authorizationRequest,
            usingStorage: sessionStorage,
            fromViewController: viewController,
            authorizationParameters: authorizationParameters) { [weak self] (authState, error) in
                guard
                    error == nil,
                    let authState = authState,
                    let authCode = authState.lastAuthorizationResponse.authorizationCode else {
                        Log.log(.error, "Concluding request with error: \(String(describing: error))")
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

                Log.log(.info, "Concluding request with sucessful code response.")
                self?.concludeAuthorizationFlow(result: .code(authorizedResponse))
        }

        state = .inProgress(authorizationRequest, carrierConfig.simInfo, completion, sessionStorage)
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
            Log.log(.warn, "Attempting to resolve url \(url) with no request in progress")
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
            concludeAuthorizationFlow(result: .error(.stateError(.generationFailed)))
            return
        }

        // validate state
        let validatedCode = response.hasMatchingState(state).promoteResult()
            // check for error
            .flatMap({ response.getError().promoteResult() })
            // extract code
            .flatMap({ response.getRequiredValue(ResponseKeys.code.rawValue).promoteResult() })

        switch validatedCode {
        case .value(let code):
            Log.log(.info, "Resolving URL with successful code.")
            concludeAuthorizationFlow(result: .code(
                    AuthorizedResponse(code: code, mcc: simInfo.mcc, mnc: simInfo.mnc)
                )
            )
        case .error(let error):
            Log.log(.error, "Resolving URL: \(url) with error: \(error)")
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
    enum Keys: String {
        case loginHintToken = "login_hint_token"
        case acrValues = "acr_values"
        case correlationId = "correlation_id"
        case context = "context"
        case prompt = "prompt"
    }

    static func createAuthorizationRequest(
        openIdServiceConfiguration: OIDServiceConfiguration,
        authorizationParameters: OpenIdAuthorizationParameters) -> OIDAuthorizationRequest {

        let additionalParams: [String: String] = [
            Keys.loginHintToken.rawValue: authorizationParameters.loginHintToken,
            Keys.acrValues.rawValue: authorizationParameters.acrValues?
                .map() { $0.rawValue }
                .joined(separator: " "),
            Keys.correlationId.rawValue: authorizationParameters.correlationId,
            Keys.context.rawValue: authorizationParameters.base64EncodedContext,
            Keys.prompt.rawValue: authorizationParameters.prompt?.rawValue,
        ].compactMapValues() { return $0 }

        // This uses the AppAuth defaults from the conveneince initializer in
        // OIDAuthorizationRequest.m
        // When we support PKCE challenges see the default imp. there as well.
        let request: OIDAuthorizationRequest = OIDAuthorizationRequest(
            configuration: openIdServiceConfiguration,
            clientId: authorizationParameters.clientId,
            clientSecret: nil, // client secret is never used in a public client.
            scope: authorizationParameters.formattedScopes,
            redirectURL: authorizationParameters.redirectURL,
            responseType: ResponseType.code.rawValue,
            state: authorizationParameters.state,
            nonce: authorizationParameters.nonce,
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

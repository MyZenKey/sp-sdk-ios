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

enum OpenIdServiceError: Error {
    case urlResponseError(URLResponseError)
    case urlResolverError(Error?)
    case stateError(RequestStateError)
    case viewControllerNotInHeirarchy
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
        authorizationParameters: OpenIdAuthorizationRequest.Parameters,
        completion: @escaping OpenIdServiceCompletion
    )

    var authorizationInProgress: Bool { get }

    func cancelCurrentAuthorizationSession()
}

class OpenIdService {
    enum State {
        case idle
        case inProgress(OpenIdAuthorizationRequest, SIMInfo, OpenIdServiceCompletion)
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
        authorizationParameters: OpenIdAuthorizationRequest.Parameters,
        completion: @escaping OpenIdServiceCompletion
        ) {

        // issuing a second authorization flow causes the first to be cancelled:
        guard case .idle = state else {
            Log.log(.warn, "Implictly cancelling existing request.")
            dismissUI {
                self.cancelCurrentAuthorizationSession()
                self.authorize(fromViewController: viewController,
                               carrierConfig: carrierConfig,
                               authorizationParameters: authorizationParameters,
                               completion: completion)
            }
            return
        }

        guard viewController.view?.window != nil else {
            completion(.error(.viewControllerNotInHeirarchy))
            return
        }

        //create the authorization request
        let authorizationRequest = OpenIdAuthorizationRequest(
            resource: carrierConfig.openIdConfig.authorizationEndpoint,
            parameters: authorizationParameters
        )

        Log.log(.info, "Performing auth request \(authorizationRequest)")
        urlResolver.resolve(
            request: authorizationRequest,
            fromViewController: viewController) { [weak self] in
                // ui triggered the dismissal and will clean itself up, just call the completion
                self?.conclude(result: .cancelled)
        }
        state = .inProgress(authorizationRequest, carrierConfig.simInfo, completion)
    }

    func cancelCurrentAuthorizationSession() {
        dismissUIAndConclude(result: .cancelled)
    }

    func resolve(url: URL) -> Bool {
        // ensure valid state:
        guard case .inProgress(let request, let simInfo, _) = state else {
            // there is no request, return
            Log.log(.warn, "Attempting to resolve url \(url) with no request in progress")
            return false
        }

        resolve(request: request, forSIMInfo: simInfo, withURL: url)
        return true
    }
}

private extension OpenIdService {
    enum ResponseKeys: String {
        case code
    }

    func resolve(
        request: OpenIdAuthorizationRequest,
        forSIMInfo simInfo: SIMInfo,
        withURL url: URL) {

        let response = ResponseURL(url: url)
        guard let state = request.parameters.state else {
            conclude(result: .error(.stateError(.generationFailed)))
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
            dismissUIAndConclude(result: .code(
                    AuthorizedResponse(code: code, mcc: simInfo.mcc, mnc: simInfo.mnc)
                )
            )
        case .error(let error):
            Log.log(.error, "Resolving URL: \(url) with error: \(error)")
            dismissUIAndConclude(result: .error(error))
        }
    }

    func conclude(result: OpenIdServiceResult) {
        defer {
            state = .idle
        }

        guard case .inProgress(_, _, let completion) = state else {
            return
        }

        completion(result)
    }

    func dismissUI(completion: @escaping () -> Void) {
        urlResolver.close {
            completion()
        }
    }

    func dismissUIAndConclude(result: OpenIdServiceResult) {
        dismissUI {
            self.conclude(result: result)
        }
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

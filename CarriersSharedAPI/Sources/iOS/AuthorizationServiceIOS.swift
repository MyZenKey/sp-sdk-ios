//
//  AuthorizationServiceIOS.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 5/3/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

class AuthorizationServiceIOSFactory: AuthorizationServiceFactory {
    func createAuthorizationService() -> AuthorizationServiceProtocol & URLHandling {
        let container: Dependencies = ProjectVerifyAppDelegate.shared.dependencies
        return AuthorizationServiceIOS(
            sdkConfig: container.resolve(),
            discoveryService: container.resolve(),
            openIdService: container.resolve(),
            carrierInfoService: container.resolve(),
            mobileNetworkSelectionService: container.resolve()
        )
    }
}

class AuthorizationServiceIOS {
    let sdkConfig: SDKConfig
    let discoveryService: DiscoveryServiceProtocol
    let openIdService: OpenIdServiceProtocol
    let carrierInfoService: CarrierInfoServiceProtocol
    let mobileNetworkSelectionService: MobileNetworkSelectionServiceProtocol

    public var isAuthorizing: Bool {
        if case .idle = state {
            return false
        } else {
            return true
        }
    }

    private var state: State = .idle {
        willSet {
            precondition(Thread.isMainThread)
        }
    }

    init(sdkConfig: SDKConfig,
         discoveryService: DiscoveryServiceProtocol,
         openIdService: OpenIdServiceProtocol,
         carrierInfoService: CarrierInfoServiceProtocol,
         mobileNetworkSelectionService: MobileNetworkSelectionServiceProtocol) {
        self.sdkConfig = sdkConfig
        self.discoveryService = discoveryService
        self.openIdService = openIdService
        self.carrierInfoService = carrierInfoService
        self.mobileNetworkSelectionService = mobileNetworkSelectionService
    }
}

extension AuthorizationServiceIOS {
    enum State {
        case idle
        case requesting(AuthorizationRequest)
    }
}

extension AuthorizationServiceIOS: AuthorizationServiceProtocol {
    public func authorize(
        scopes: [ScopeProtocol],
        fromViewController viewController: UIViewController,
        acrValues: [ACRValue]? = [.aal1],
        state: String? = nil,
        correlationId: String? = nil,
        context: String? = nil,
        prompt: PromptValue? = nil,
        nonce: String? = nil,
        completion: @escaping AuthorizationCompletion) {

        precondition(Thread.isMainThread, "You should only call `authorize` from the main thread.")

        let parameters = OpenIdAuthorizationParameters(
            clientId: sdkConfig.clientId,
            redirectURL: sdkConfig.redirectURL,
            formattedScopes: OpenIdScopes(requestedScopes: scopes).networkFormattedString,
            state: state ?? RandomStringGenerator.generateStateSuitableString(),
            nonce: nonce,
            acrValues: acrValues,
            prompt: prompt,
            correlationId: correlationId,
            context: context,
            loginHintToken: nil
        )

        let request = AuthorizationRequest(
            viewController: viewController,
            authorizationParameters: parameters,
            completion: completion
        )

        if case .requesting = self.state {
            cancel() // will always execute synchronously per precondition above.
        }

        self.state = .requesting(request)

        request.mainQueueUpdate(state: .discovery(carrierInfoService.primarySIM))
        next(for: request)
    }

    public func cancel() {
        precondition(Thread.isMainThread, "You should only call `cancel` from the main thread.")
        guard case .requesting(let request) = state else {
            return
        }

        request.mainQueueUpdate(state: .concluding(.cancelled))
        next(for: request)
    }
}

extension AuthorizationServiceIOS: URLHandling {
    func resolve(url: URL) -> Bool {
        guard case .requesting(let request) = state else {
            return false
        }

        switch request.state {
        case .authorization:
            return openIdService.resolve(url: url)

        case .mobileNetworkSelection:
            return mobileNetworkSelectionService.resolve(url: url)

        default:
            return false
        }
    }
}

private extension AuthorizationServiceIOS {
    /// This function wraps step transitions and ensures that the request should continue before
    /// advancing to the next step.
    func next(for request: AuthorizationRequest) {

        precondition(Thread.isMainThread)

        guard !request.isFinished else {
            // if the request has previously been concluded, we can assume that any further commands
            // should be ignored and we can return
            return
        }

        // if the request is still in progress
        // begin the next appropriate step in the autorization process
        let logStringBase = "State Change:"
        switch request.state {
        case .undefined, .finished:
            break

        case .discovery(let simInfo):
            Log.log(.info, "\(logStringBase) Perform Discovery")
            performDiscovery(with: simInfo)

        case .mobileNetworkSelection(let resource):
            Log.log(.info, "\(logStringBase) Discovery UI")
            showDiscoveryUI(usingResource: resource)

        case .authorization(let discoveredConfig):
            Log.log(.info, "\(logStringBase) Perform Authorization")
            showAuthorizationUI(usingConfig: discoveredConfig)

        case .missingUserRecovery:
            Log.log(.info, "\(logStringBase) Attempt Missing User Recovery")
            performDiscovery(with: nil)

        case .concluding(let outcome):

            var logLevel: Log.Level = .info
            if case .error = outcome {
                logLevel = .error
            }
            Log.log(logLevel, "\(logStringBase) Conclusion: \(outcome)")

            request.update(state: .finished)
            state = .idle
        }
    }
}

private extension AuthorizationServiceIOS {
    func performDiscovery(with simInfo: SIMInfo?) {
        guard case .requesting(let request) = state else {
            return
        }

        discoveryService.discoverConfig(
            forSIMInfo: simInfo,
            prompt: request.passPrompt) { [weak self] result in

            defer { self?.next(for: request) }

            switch result {
            case .knownMobileNetwork(let config):
                request.mainQueueUpdate(state: .authorization(config))

            case .unknownMobileNetwork(let redirect):
                request.mainQueueUpdate(state: .mobileNetworkSelection(redirect.redirectURI))

            case .error(let error):
                let authorizationError = error.asAuthorizationError
                request.mainQueueUpdate(state: .concluding(.error(authorizationError)))
            }
        }
    }

    func showAuthorizationUI(usingConfig config: CarrierConfig) {
        guard case .requesting(let request) = state else {
            return
        }

        openIdService.authorize(
            fromViewController: request.viewController,
            carrierConfig: config,
            authorizationParameters: request.authorizationParameters) { [weak self] result in

                defer { self?.next(for: request) }

                switch result {
                case .code(let response):
                    request.mainQueueUpdate(state: .concluding(.code(response)))

                case .error(let error):
                    let authorizationError = error.asAuthorizationError
                    let nextState = AuthorizationServiceIOS.recoveryState(forError: authorizationError)
                    request.mainQueueUpdate(state: nextState)

                case .cancelled:
                    request.mainQueueUpdate(state: .concluding(.cancelled))
                }
        }
    }

    func showDiscoveryUI(usingResource resource: URL) {
        guard case .requesting(let request) = state else {
            return
        }

        self.mobileNetworkSelectionService.requestUserNetworkSelection(
            fromResource: resource,
            fromCurrentViewController: request.viewController,
            prompt: request.passPrompt
        ) { [weak self] result in

            defer { self?.next(for: request) }

            switch result {
            case .networkInfo(let response):
                request.authorizationParameters.loginHintToken = response.loginHintToken
                request.mainQueueUpdate(state: .discovery(response.simInfo))

            case .error(let error):
                let authorizationError = error.asAuthorizationError
                request.mainQueueUpdate(state: .concluding(.error(authorizationError)))

            case .cancelled:
                request.mainQueueUpdate(state: .concluding(.cancelled))
            }
        }
    }
}

private extension AuthorizationServiceIOS {
    static func recoveryState(forError error: AuthorizationError) -> AuthorizationRequest.State {
        switch error.code {
        case ProjectVerifyErrorCode.userNotFound.rawValue:
            return .missingUserRecovery

        default:
            return .concluding(.error(error))
        }
    }
}

private extension AuthorizationRequest {
    func mainQueueUpdate(state: AuthorizationRequest.State) {
        precondition(Thread.isMainThread)
        self.update(state: state)
    }
}

//
//  IOSAuthorizationService.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 5/3/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

class AuthorizationServiceIOSFactory: AuthorizationServiceFactory {
    func createAuthorizationService() -> AuthorizationServiceProtocol {
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

    /// always update on main thread
    private var state: State = .idle

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
        case requesting(Request)
    }

    class Request {
        enum State {
            case undefined
            case discovery(SIMInfo?)
            case mobileNetworkSelection(URL)
            case authorization(CarrierConfig)
            case missingUserRecovery
            case concluding(AuthorizationResult)
            case finished
        }

        var isFinished: Bool {
            if case .finished = state {
                return true
            } else {
                return false
            }
        }

        var passPrompt: Bool {
            return isAttemptingRecovery
        }

        /// If this flag is set on the request the prompt flag should be sent to all disocvery
        /// endpoints and all cookies should be ignored. If this flag is already set for a request
        /// recovery should not be attempted a second time.
        private(set) var isAttemptingRecovery: Bool = false

        private(set) var state: State = .undefined {
            didSet {
                if case .missingUserRecovery = state {
                    // set a flat to indicate we're attempting user recovery:
                    isAttemptingRecovery = true
                }
            }
        }

        var authorizationParameters: OpenIdAuthorizationParameters

        let viewController: UIViewController
        private let completion: AuthorizationCompletion

        init(viewController: UIViewController,
             authorizationParameters: OpenIdAuthorizationParameters,
             completion: @escaping AuthorizationCompletion) {
            self.viewController = viewController
            self.authorizationParameters = authorizationParameters
            self.completion = completion
        }

        func update(state: State) {
            guard !isFinished else {
                return
            }
            self.state = state
        }

        func executeCompletion() {
            guard case .concluding(let outcome) = state else {
                return
            }

            state = .finished
            completion(outcome)
        }
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
            redirectURL: sdkConfig.redirectURL(forRoute: .authorize),
            formattedScopes: OpenIdScopes(requestedScopes: scopes).networkFormattedString,
            state: state ?? RandomStringGenerator.generateStateSuitableString(),
            nonce: nonce,
            acrValues: acrValues,
            prompt: prompt,
            correlationId: correlationId,
            context: context,
            loginHintToken: nil
        )

        let request = Request(
            viewController: viewController,
            authorizationParameters: parameters,
            completion: completion
        )

        if case .requesting = self.state {
            cancel() // will always execute synchronously per precondition above.
        }

        self.state = .requesting(request)

        request.update(state: .discovery(carrierInfoService.primarySIM))
        next(forRequest: request)
    }

    func cancel() {
        precondition(Thread.isMainThread, "You should only call `cancel` from the main thread.")
        guard case .requesting(let request) = state else {
            return
        }

        request.update(state: .concluding(.cancelled))
        next(forRequest: request)
    }
}

private extension AuthorizationServiceIOS {

    /// This function wraps step transitions and ensures that the request should continue before
    /// advancing to the next step.
    func next(forRequest request: Request) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.next(forRequest: request)
            }
            return
        }

        guard !request.isFinished else {
            // if the request has previously been concluded, we can assume that any further commands
            // should be ignored and we can return
            return
        }

        // if the request is still in progress
        // begin the next appropriate step in the autorization process
        switch request.state {
        case .undefined, .finished:
            break

        case .discovery(let simInfo):
            performDiscovery(withSIMInfo: simInfo)

        case .mobileNetworkSelection(let resource):
            showDiscoveryUI(usingResource: resource)

        case .authorization(let discoveredConfig):
            showAuthorizationUI(usingConfig: discoveredConfig)

        case .missingUserRecovery:
            performDiscovery(withSIMInfo: nil)

        case .concluding:
            request.executeCompletion()
            state = .idle
        }
    }
}

extension AuthorizationServiceIOS {
    func performDiscovery(withSIMInfo simInfo: SIMInfo?) {
        guard case .requesting(let request) = state else {
            return
        }

        discoveryService.discoverConfig(
            forSIMInfo: simInfo,
            prompt: request.passPrompt) { [weak self] result in

            defer { self?.next(forRequest: request) }

            switch result {
            case .knownMobileNetwork(let config):
                request.update(state: .authorization(config))

            case .unknownMobileNetwork(let redirect):
                // TODO: - Limit the number of times this flow can be executed.
                request.update(state: .mobileNetworkSelection(redirect.redirectURI))

            case .error(let error):
                let authorizationError = error.asAuthorizationError
                request.update(state: .concluding(.error(authorizationError)))
                // TODO: -
                self?.showConsolation("an error occurred during discovery \(error)", on: request.viewController)
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

                defer { self?.next(forRequest: request) }

                guard let `self` = self else {
                    return
                }

                switch result {
                case .code(let response):
                    request.update(state: .concluding(.code(response)))

                case .error(let error):
                    let authorizationError = error.asAuthorizationError

                    guard !self.recover(fromError: authorizationError, duringRequest: request) else {
                        return
                    }

                    request.update(state: .concluding(.error(authorizationError)))
                    // TODO: -
                    self.showConsolation("an error occurred during discovery \(error)", on: request.viewController)

                case .cancelled:
                    request.update(state: .concluding(.cancelled))
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

            defer { self?.next(forRequest: request) }

            switch result {
            case .networkInfo(let response):
                request.authorizationParameters.loginHintToken = response.loginHintToken
                request.update(state: .discovery(response.simInfo))

            case .error(let error):
                let authorizationError = error.asAuthorizationError
                request.update(state: .concluding(.error(authorizationError)))
                // TODO: -
                self?.showConsolation("an error occurred during discovery \(error)", on: request.viewController)

            case .cancelled:
                request.update(state: .concluding(.cancelled))
            }
        }
    }
}

private extension AuthorizationServiceIOS {
    func recover(fromError error: AuthorizationError, duringRequest request: Request) -> Bool {
        switch error.code {
        case ProjectVerifyErrorCode.userNotFound.rawValue:
            guard !request.isAttemptingRecovery else {
                return false
            }

            request.update(state: .missingUserRecovery)
            next(forRequest: request)
            return true

        default:
            return false
        }
    }
}

// TODO: Remove this, just for qa
private extension AuthorizationServiceIOS {
    func showConsolation(_ text: String, on viewController: UIViewController) {
        let controller = UIAlertController(title: "Demo", message: text, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
        viewController.present(controller, animated: true, completion: nil)
    }
}

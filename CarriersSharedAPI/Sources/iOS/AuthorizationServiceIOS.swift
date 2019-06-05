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

    enum Step {
        case discovery(SIMInfo?)
        case mobileNetworkSelection(URL)
        case authorization(CarrierConfig)
        case conclusion(AuthorizationResult)
    }

    class Request {
        private(set) var isFinished: Bool = false
        private(set) var isCancelled: Bool = false {
            didSet {
                conclude(withOutcome: .cancelled)
            }
        }

        let viewController: UIViewController
        var authorizationParameters: OpenIdAuthorizationParameters
        private let completion: AuthorizationCompletion

        init(viewController: UIViewController,
             authorizationParameters: OpenIdAuthorizationParameters,
             completion: @escaping AuthorizationCompletion) {
            self.viewController = viewController
            self.authorizationParameters = authorizationParameters
            self.completion = completion
        }

        func cancel() {
            isCancelled = true
        }

        func conclude(withOutcome outcome: AuthorizationResult) {
            guard !isFinished else { return }
            completion(outcome)
            isFinished = true
        }
    }
}

private extension AuthorizationServiceIOS {

    /// This function wraps step transitions and ensures that the request should continue before
    /// advancing to the next step.
    func transition(request: Request, toStep step: Step) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.transition(request: request, toStep: step)
            }
            return
        }

        guard !request.isFinished else {
            // if the request has previously been concluded, we can assume that any further commands
            // should be ignored and can return
            return
        }

        switch step {
        case .discovery(let simInfo):
            performDiscovery(withSIMInfo: simInfo)

        case .mobileNetworkSelection(let resource):
            showDiscoveryUI(usingResource: resource)

        case .authorization(let discoveredConfig):
            showAuthorizationUI(usingConfig: discoveredConfig)

        case .conclusion(let result):
            conclude(request: request, withOutcome: result)
        }
    }

    func conclude(request: Request, withOutcome outcome: AuthorizationResult) {
        request.conclude(withOutcome: outcome)
        state = .idle
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

        precondition(Thread.isMainThread, "You should call `authorize` from the main thread.")

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

        transition(request: request, toStep: .discovery(carrierInfoService.primarySIM))
    }

    func cancel() {
        guard case .requesting(let request) = state else {
            return
        }

        transition(request: request, toStep: .conclusion(.cancelled))
    }
}

extension AuthorizationServiceIOS {
    func performDiscovery(withSIMInfo simInfo: SIMInfo?) {
        guard case .requesting(let request) = state else {
            return
        }

        discoveryService.discoverConfig(forSIMInfo: simInfo) { [weak self] result in
            switch result {
            case .knownMobileNetwork(let config):
                self?.transition(request: request, toStep: .authorization(config))

            case .unknownMobileNetwork(let redirect):
                self?.transition(request: request, toStep: .mobileNetworkSelection(redirect.redirectURI))

            case .error(let error):
                let authorizationError = error.asAuthorizationError
                self?.transition(request: request, toStep: .conclusion(.error(authorizationError)))

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
                switch result {
                case .code(let response):
                    self?.transition(request: request, toStep: .conclusion(.code(response)))

                case .error(let error):
                    let authorizationError = error.asAuthorizationError
                    self?.transition(request: request, toStep: .conclusion(.error(authorizationError)))
                    // TODO: -
                    self?.showConsolation("an error occurred during discovery \(error)", on: request.viewController)

                case .cancelled:
                    self?.transition(request: request, toStep: .conclusion(.cancelled))
                }
        }
    }

    func showDiscoveryUI(usingResource resource: URL) {
        guard case .requesting(let request) = state else {
            return
        }

        self.mobileNetworkSelectionService.requestUserNetworkSelection(
            fromResource: resource,
            fromCurrentViewController: request.viewController
        ) { [weak self] result in
            switch result {
            case .networkInfo(let response):
                request.authorizationParameters.loginHintToken = response.loginHintToken
                self?.transition(request: request, toStep: .discovery(response.simInfo))

            case .error(let error):
                let authorizationError = error.asAuthorizationError
                self?.transition(request: request, toStep: .conclusion(.error(authorizationError)))
                // TODO: -
                self?.showConsolation("an error occurred during discovery \(error)", on: request.viewController)

            case .cancelled:
                self?.transition(request: request, toStep: .conclusion(.cancelled))
            }
        }
    }
}

private extension AuthorizationServiceIOS {
    func canRecover(fromError error: AuthorizationError) -> Bool {
        return false
    }

    func recover(fromError error: AuthorizationError) {

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

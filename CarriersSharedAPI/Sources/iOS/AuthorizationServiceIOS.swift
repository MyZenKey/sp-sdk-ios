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

        let parameters = OpenIdAuthorizationParameters(
            clientId: sdkConfig.clientId,
            redirectURL: sdkConfig.redirectURL(forRoute: .authorize),
            formattedScopes: OpenIdScopes(requestedScopes: scopes).networkFormattedString,
            state: state ?? StateGenerator.generate(),
            nonce: nonce ?? StateGenerator.generate(),
            acrValues: acrValues,
            prompt: prompt,
            correlationId: correlationId,
            context: context,
            loginHintToken: nil
        )

        performDiscovery(
            withSIMInfo: carrierInfoService.primarySIM,
            authorizationParameters: parameters,
            fromViewController: viewController,
            completion: completion
        )
    }
}

extension AuthorizationServiceIOS {
    // TODO: Remove this, just for qa
    func showConsolation(_ text: String, on viewController: UIViewController) {
        let controller = UIAlertController(title: "Demo", message: text, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
        viewController.present(controller, animated: true, completion: nil)
    }

    func performDiscovery(
        withSIMInfo simInfo: SIMInfo?,
        authorizationParameters: OpenIdAuthorizationParameters,
        fromViewController viewController: UIViewController,
        completion: @escaping AuthorizationCompletion) {

        discoveryService.discoverConfig(forSIMInfo: simInfo) { [weak self] result in
            switch result {
            case .knownMobileNetwork(let config):
                self?.showAuthorizationUI(
                    usingConfig: config,
                    withAuthorizationParameters: authorizationParameters,
                    fromViewController: viewController,
                    completion: completion
                )
            case .unknownMobileNetwork(let redirect):
                self?.showDiscoveryUI(
                    usingResource: redirect.redirectURI,
                    withAuthorizationParameters: authorizationParameters,
                    fromViewController: viewController,
                    completion: completion
                )
            case .error(let error):
                let authorizationError = error.asAuthorizationError
                completion(.error(authorizationError))
                // TODO: -
                self?.showConsolation("an error occurred during discovery \(error)", on: viewController)
            }
        }
    }

    func showAuthorizationUI(usingConfig config: CarrierConfig,
                             withAuthorizationParameters parameters: OpenIdAuthorizationParameters,
                             fromViewController viewController: UIViewController,
                             completion: @escaping AuthorizationCompletion) {

        openIdService.authorize(
            fromViewController: viewController,
            carrierConfig: config,
            authorizationParameters: parameters) { [weak self] result in
                switch result {
                case .code(let response):
                    completion(.code(response))
                case .error(let error):
                    let authorizationError = error.asAuthorizationError
                    completion(.error(authorizationError))
                    // TODO: -
                    self?.showConsolation("an error occurred during discovery \(error)", on: viewController)
                case .cancelled:
                    completion(.cancelled)
                }
        }
    }

    func showDiscoveryUI(usingResource resource: URL,
                         withAuthorizationParameters parameters: OpenIdAuthorizationParameters,
                         fromViewController viewController: UIViewController,
                         completion: @escaping AuthorizationCompletion) {

        self.mobileNetworkSelectionService.requestUserNetworkSelection(
            fromResource: resource,
            fromCurrentViewController: viewController
        ) { [weak self] result in
            switch result {
            case .networkInfo(let response):
                var updatedParameters = parameters
                updatedParameters.loginHintToken = response.loginHintToken
                self?.performDiscovery(
                    withSIMInfo: response.simInfo,
                    authorizationParameters: updatedParameters,
                    fromViewController: viewController,
                    completion: completion
                )
            case .error(let error):
                let authorizationError = error.asAuthorizationError
                completion(.error(authorizationError))
                // TODO: -
                self?.showConsolation("an error occurred during discovery \(error)", on: viewController)
            case .cancelled:
                completion(.cancelled)
            }
        }
    }
}

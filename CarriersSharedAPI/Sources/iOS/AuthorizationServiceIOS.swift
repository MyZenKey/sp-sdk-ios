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
    public func connectWithProjectVerify(
        scopes: [ScopeProtocol],
        fromViewController viewController: UIViewController,
        completion: @escaping AuthorizationCompletion) {

        performDiscovery(
            forSIMInfo: carrierInfoService.primarySIM,
            scopes: scopes,
            fromViewController: viewController,
            authorizationContextParameters: .none,
            completion: completion
        )
    }
}

extension AuthorizationServiceIOS {

    struct AuthorizationContextParameters {
        let loginHintToken: String?

        static let none = AuthorizationContextParameters(loginHintToken: nil)
    }

    // TODO: Remove this, just for qa
    func showConsolation(_ text: String, on viewController: UIViewController) {
        let controller = UIAlertController(title: "Demo", message: text, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
        viewController.present(controller, animated: true, completion: nil)
    }

    func performDiscovery(forSIMInfo simInfo: SIMInfo?,
                          scopes: [ScopeProtocol],
                          fromViewController viewController: UIViewController,
                          authorizationContextParameters: AuthorizationContextParameters,
                          completion: @escaping AuthorizationCompletion) {

        discoveryService.discoverConfig(forSIMInfo: simInfo) { [weak self] result in
            switch result {
            case .knownMobileNetwork(let config):
                self?.showAuthorizationUI(
                    usingConfig: config,
                    scopes: scopes,
                    fromViewController: viewController,
                    authorizationContextParameters: authorizationContextParameters,
                    completion: completion
                )
            case .unknownMobileNetwork(let redirect):
                self?.showDiscoveryUI(
                    usingResource: redirect.redirectURI,
                    scopes: scopes,
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
                             scopes: [ScopeProtocol],
                             fromViewController viewController: UIViewController,
                             authorizationContextParameters: AuthorizationContextParameters,
                             completion: @escaping AuthorizationCompletion) {

        let authorizationConfig = OpenIdAuthorizationConfig(
            simInfo: config.simInfo,
            clientId: sdkConfig.clientId,
            authorizationEndpoint: config.openIdConfig.authorizationEndpoint,
            tokenEndpoint: config.openIdConfig.tokenEndpoint,
            formattedScopes: OpenIdScopes(requestedScopes: scopes).networkFormattedString,
            redirectURL: sdkConfig.redirectURL(forRoute: .authorize),
            loginHintToken: authorizationContextParameters.loginHintToken,
            state: "demo-app-state"
        )

        openIdService.authorize(
            fromViewController: viewController,
            authorizationConfig: authorizationConfig) { [weak self] result in
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
                         scopes: [ScopeProtocol],
                         fromViewController viewController: UIViewController,
                         completion: @escaping AuthorizationCompletion) {

        self.mobileNetworkSelectionService.requestUserNetworkSelection(
            fromResource: resource,
            fromCurrentViewController: viewController
        ) { [weak self] result in
            switch result {
            case .networkInfo(let response):
                let contextParams = AuthorizationContextParameters(
                    loginHintToken: response.loginHintToken
                )
                self?.performDiscovery(
                    forSIMInfo: response.simInfo,
                    scopes: scopes,
                    fromViewController: viewController,
                    authorizationContextParameters: contextParams,
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

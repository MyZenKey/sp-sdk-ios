//
//  AuthorizationService.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/19/19.
//  Copyright © 2018 XCI JV, LLC. ALL RIGHTS RESERVED.
//

import AppAuth
import UIKit

protocol AuthorizationServiceProtocol {
    /// Requests authorization for the specified scopes from Project Verify.
    /// - Parameters:
    ///   - scopes: an array of scopes to be authorized for access. See the predefined
    ///     `Scope` for a list of supported scope types.
    ///   - viewController: the UI context from which the authorization request originated
    ///    this is used as the presentation view controller if additional ui is required for resolving
    ///    the request.
    ///   - completion: an escaping block executed asynchronously, on the main thread. This
    ///    block will take one parameter, a result, see `AuthorizationResult` for more information.
    ///
    /// - SeeAlso: ScopeProtocol
    /// - SeeAlso: Scopes
    /// - SeeAlso: AuthorizationResult
    func connectWithProjectVerify(
        scopes: [ScopeProtocol],
        fromViewController viewController: UIViewController,
        completion: @escaping AuthorizationCompletion)
}

/// This service provides an interface for authorizing an application with Project Verify.
public class AuthorizationService {
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

extension AuthorizationService: AuthorizationServiceProtocol {
    public func connectWithProjectVerify(
        scopes: [ScopeProtocol],
        fromViewController viewController: UIViewController,
        completion: @escaping AuthorizationCompletion) {

        performDiscovery(
            forSIMInfo: carrierInfoService.primarySIM,
            scopes: scopes,
            fromViewController: viewController,
            completion: completion
        )
    }
}

private extension AuthorizationService {
    // TODO: Remove this, just for qa
    func showConsolation(_ text: String, on viewController: UIViewController) {
        let controller = UIAlertController(title: "Demo", message: text, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
        viewController.present(controller, animated: true, completion: nil)
    }

    func performDiscovery(forSIMInfo simInfo: SIMInfo?,
                          scopes: [ScopeProtocol],
                          fromViewController viewController: UIViewController,
                          completion: @escaping AuthorizationCompletion) {

        let sdkConfig = self.sdkConfig
        discoveryService.discoverConfig(forSIMInfo: simInfo) { [weak self] result in
            switch result {
            case .knownMobileNetwork(let config):

                let authorizationConfig = OpenIdAuthorizationConfig(
                    simInfo: config.simInfo,
                    clientId: sdkConfig.clientId,
                    authorizationEndpoint: config.openIdConfig.authorizationEndpoint,
                    tokenEndpoint: config.openIdConfig.tokenEndpoint,
                    formattedScopes: OpenIdScopes(requestedScopes: scopes).networkFormattedString,
                    redirectURL: sdkConfig.redirectURL(forRoute: .authorize),
                    state: "demo-app-state"
                )

                self?.openIdService.authorize(
                    fromViewController: viewController,
                    authorizationConfig: authorizationConfig,
                    completion: completion
                )

            case .unknownMobileNetwork(let redirect):
                self?.showDiscoveryUI(
                    usingResource: redirect.redirectURI,
                    scopes: scopes,
                    fromViewController: viewController,
                    completion: completion
                )
                break
            case .error(let error):
                completion(.error(error))
                // TODO: -
                self?.showConsolation("an error occurred during discovery \(error)", on: viewController)
                break
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
            case .networkInfo(let simInfo):
                self?.performDiscovery(
                    forSIMInfo: simInfo,
                    scopes: scopes,
                    fromViewController: viewController,
                    completion: completion
                )
            case .error(let error):
                completion(.error(error))
            case .cancelled:
                completion(.cancelled)
            }
        }
    }
}

public extension AuthorizationService {
    /// creates a new instance of an `AuthorizationService`
    convenience init() {
        let container: Dependencies = ProjectVerifyAppDelegate.shared.dependencies
        self.init(
            sdkConfig: container.resolve(),
            discoveryService: container.resolve(),
            openIdService: container.resolve(),
            carrierInfoService: container.resolve(),
            mobileNetworkSelectionService: container.resolve()
        )
    }
}

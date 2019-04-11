//
//  AuthorizationService.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/19/19.
//  Copyright © 2018 XCI JV, LLC. ALL RIGHTS RESERVED.
//

import AppAuth
import UIKit

/// This service provides an interface for authorizing an application with Project Verify.
public class AuthorizationService {
    let sdkConfig: SDKConfig
    let discoveryService: DiscoveryServiceProtocol
    let openIdService: OpenIdServiceProtocol

    init(sdkConfig: SDKConfig,
         discoveryService: DiscoveryServiceProtocol,
         openIdService: OpenIdServiceProtocol) {
        self.sdkConfig = sdkConfig
        self.discoveryService = discoveryService
        self.openIdService = openIdService
    }

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
    public func connectWithProjectVerify(
        scopes: [ScopeProtocol],
        fromViewController viewController: UIViewController,
        completion: @escaping AuthorizationCompletion) {

        let sdkConfig = self.sdkConfig

        discoveryService.discoverConfig() { [weak self] result in
            switch result {
            case .knownMobileNetwork(let config):

                let authorizationConfig = OpenIdAuthorizationConfig(
                    simInfo: config.simInfo,
                    clientId: sdkConfig.clientId,
                    // TODO: fix these forcing optionals here and strongly type upstream
                    authorizationEndpoint: config.openIdConfig.authorizationEndpoint,
                    tokenEndpoint: config.openIdConfig.tokenEndpoint,
                    formattedScopes: OpenIdScopes(requestedScopes: scopes).networkFormattedString,
                    redirectURL: sdkConfig.redirectURL,
                    state: "demo-app-state"
                )

                self?.openIdService.authorize(
                    fromViewController: viewController,
                    authorizationConfig: authorizationConfig,
                    completion: completion
                )
            case .unknownMobileNetwork:
                completion(.error(UnsupportedCarrier()))
                // TODO: -
                self?.showConsolation("sim not recognized during discovery", on: viewController)
                break
            case .noMobileNetwork:
                // TODO: -
                // secondary device flow
                completion(.error(UnknownError()))
                self?.showConsolation("no sim set up to use for discovery", on: viewController)
                break
            case .error(let error):
                completion(.error(error))
                // TODO: -
                self?.showConsolation("an error occurred during discovery \(error)", on: viewController)
                break
            }
        }
    }
}

private extension AuthorizationService {
    // TODO: Remove this, just for qa
    func showConsolation(_ text: String, on viewController: UIViewController) {
        let controller = UIAlertController(title: "Demo", message: text, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
        viewController.present(controller, animated: true, completion: nil)
    }
}

public extension AuthorizationService {

    /// creates a new instance of an `AuthorizationService`
    convenience init() {
        let appDelegate = ProjectVerifyAppDelegate.shared
        self.init(
            sdkConfig: appDelegate.sdkConfig,
            discoveryService: Dependencies.resolve(),
            openIdService: Dependencies.resolve()
        )
    }
}

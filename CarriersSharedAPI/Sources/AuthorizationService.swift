//
//  AuthorizationService.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/19/19.
//  Copyright © 2018 XCI JV, LLC. ALL RIGHTS RESERVED.
//

import AppAuth
import UIKit

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
                    authorizationEndpoint: URL(string: config.openIdConfig["authorization_endpoint"]!)!,
                    tokenEndpoint: URL(string: config.openIdConfig["token_endpoint"]!)!,
                    formattedScopes: OpenIdScopes(requestedScopes: scopes).networkFormattedString,
                    redirectURL: sdkConfig.redirectURL,
                    state: config.carrier.shortName
                )

                self?.openIdService.authorize(
                    fromViewController: viewController,
                    authorizationConifg: authorizationConfig,
                    completion: completion
                )
            case .unknownMobileNetwork:
                // TODO: -
                self?.showConsolation("sim not recognized during discovery", on: viewController)
                break
            case .noMobileNetwork:
                // TODO: -
                self?.showConsolation("no sim set up to use for discovery", on: viewController)
                break
            case .error(let error):
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
    convenience init() {
        // use AppDelegate as a dependency container until we have a clearer idea of what we want
        let appDelegate = ProjectVerifyAppDelegate.shared
        let dependencies = appDelegate.dependencies
        self.init(
            sdkConfig: appDelegate.sdkConfig,
            discoveryService: dependencies.discoveryService,
            openIdService: dependencies.openIdService
        )
    }
}

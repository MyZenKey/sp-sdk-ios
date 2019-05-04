//
//  IOSRouter.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 5/3/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

class RouterIOS: RouterServiceProtocol {
    public func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {

        let dependencies: Dependencies = ProjectVerifyAppDelegate.shared.dependencies

        // make sure we have a route this sdk can handle:
        guard let route = Route(rawValue: url.path) else {
            return false
        }

        let service: URLHandling
        switch route {
        case .authorize:
            let openIdService: OpenIdServiceProtocol = dependencies.resolve()
            service = openIdService
        case .discoveryUI:
            let mobileNetworkSelectionService: MobileNetworkSelectionServiceProtocol = dependencies.resolve()
            service = mobileNetworkSelectionService
            // TODO: - We don't have a spec for other states that might be resolved via this url.
            // add those here when we do
        }

        return service.resolve(url: url)
    }
}

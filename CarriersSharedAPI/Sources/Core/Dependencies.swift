//
//  Dependencies.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/28/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
#if os(iOS)
import CoreTelephony
#endif

class Dependencies {
    let sdkConfig: SDKConfig

    private(set) var all: [Any] = []

    init(sdkConfig: SDKConfig) {
        self.sdkConfig = sdkConfig
    }

    private func buildDependencies() {
        #if os(iOS)
            let carrierInfoService = CarrierInfoService(
                mobileNetworkInfoProvder: CTTelephonyNetworkInfo()
            )

            let configCacheService = ConfigCacheService(
                networkIdentifierCache: NetworkIdentifierCache.bundledCarrierLookup
            )

            let discoveryService = DiscoveryService(
                networkService: NetworkService(),
                configCacheService: configCacheService
            )

            let mobileNetworkSelectionService = MobileNetworkSelectionService(
                sdkConfig: self.sdkConfig,
                mobileNetworkSelectionUI: MobileNetworkSelectionUI()
            )

            let openIdService = OpenIdService(
                urlResolver: XCISchemeOpenIdURLResolver()
            )

            let iosRouter = RouterIOS()

            let iosAuthorizationServiceFactory = AuthorizationServiceIOSFactory()

            all = [
                carrierInfoService,
                configCacheService,
                discoveryService,
                mobileNetworkSelectionService,
                openIdService,
                iosRouter,
                iosAuthorizationServiceFactory,
            ]
        #elseif os(tvOS)

        #endif
    }
}

extension Dependencies {
    func resolve<T>() -> T {
        let firstResolution = all.compactMap { $0 as? T }.first
        guard let resolved = firstResolution else {
            fatalError("attemtping to resolve a dependency that doesn't exist")
        }
        return resolved
    }
}

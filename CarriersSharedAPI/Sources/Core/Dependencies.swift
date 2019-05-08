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
        self.buildDependencies()
    }

    private func buildDependencies() {
        let configCacheService = ConfigCacheService(
            networkIdentifierCache: NetworkIdentifierCache.bundledCarrierLookup
        )

        let discoveryService = DiscoveryService(
            networkService: NetworkService(),
            configCacheService: configCacheService
        )

        let router = Router()

        #if os(iOS)
            let carrierInfoService = CarrierInfoService(
                mobileNetworkInfoProvder: CTTelephonyNetworkInfo()
            )

            let mobileNetworkSelectionService = MobileNetworkSelectionService(
                sdkConfig: self.sdkConfig,
                mobileNetworkSelectionUI: MobileNetworkSelectionUIIOS()
            )

            let openIdService = OpenIdService(
                urlResolver: OpenIdURLResolverIOS()
            )

            let authorizationServiceFactoryIOS = AuthorizationServiceIOSFactory()

            let brandingProvider = CurrentSIMBrandingProvider(
                configCacheService: configCacheService,
                carrierInfoService: carrierInfoService
            )

            all = [
                sdkConfig,
                carrierInfoService,
                configCacheService,
                discoveryService,
                mobileNetworkSelectionService,
                openIdService,
                router,
                authorizationServiceFactoryIOS,
                brandingProvider,
            ]
        #elseif os(tvOS)

        // TODO: tvOS Network Selection UI
//        let mobileNetworkSelectionService = MobileNetworkSelectionService(
//            sdkConfig: self.sdkConfig,
//            mobileNetworkSelectionUI: MobileNetworkSelectionUIIOS()
//        )

        // TOOD: tvOS OpenIDURLResolver
//        let openIdService = OpenIdService(
//            urlResolver: OpenIdURLResolverIOS()
//        )

        // TODO: tvOS Authorization Service Factory
//        let iosAuthorizationServiceFactory = AuthorizationServiceIOSFactory()

        // TODO: tvOS Branding Provider
//        let brandingProvider = CurrentSIMBrandingProvider(
//            configCacheService: configCacheService,
//            carrierInfoService: carrierInfoService
//        )

        all = [
            sdkConfig,
            configCacheService,
            discoveryService,
            router,
//            mobileNetworkSelectionService,
//            openIdService,
//            iosAuthorizationServiceFactory,
//            brandingProvider,
        ]

        #endif
    }
}

extension Dependencies {
    func resolve<T>() -> T {
        let firstResolution = all.compactMap { $0 as? T }.first
        guard let resolved = firstResolution else {
            fatalError("attemtping to resolve a dependency of type \(T.self) that doesn't exist")
        }
        return resolved
    }
}

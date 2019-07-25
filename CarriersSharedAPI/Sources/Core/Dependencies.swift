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

public enum ProjectVerifyOptionKeys: String {
    case qaHost
    case logLevel
}

public typealias ProjectVerifyOptions = [ProjectVerifyOptionKeys: Any]

class Dependencies {
    let sdkConfig: SDKConfig
    let options: ProjectVerifyOptions

    private(set) var all: [Any] = []

    init(sdkConfig: SDKConfig, options: ProjectVerifyOptions = [:]) {
        self.sdkConfig = sdkConfig
        self.options = options
        self.buildDependencies()
    }

    private func buildDependencies() {
        let host: ProjectVerifyNetworkConfig.Host = (options[.qaHost] as? Bool ?? false) ?
            .qa :
            .production

        let hostConfig = ProjectVerifyNetworkConfig(host: host)

        let configCacheService = ConfigCacheService(
            networkIdentifierCache: NetworkIdentifierCache.bundledCarrierLookup
        )

        let discoveryService = DiscoveryService(
            sdkConfig: sdkConfig,
            hostConfig: hostConfig,
            networkService: NetworkService(),
            configCacheService: configCacheService
        )

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
                hostConfig,
                carrierInfoService,
                configCacheService,
                discoveryService,
                mobileNetworkSelectionService,
                openIdService,
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
            hostConfig,
            configCacheService,
            discoveryService,
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

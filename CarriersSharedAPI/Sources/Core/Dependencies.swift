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
    case mockedCarrier
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

        Log.configureLogger(level: options.logLevel)
        let host: ProjectVerifyNetworkConfig.Host = options.host

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
                mobileNetworkInfoProvider: resolveNetworkInfoProvider()
            )

            let mobileNetworkSelectionService = MobileNetworkSelectionService(
                sdkConfig: self.sdkConfig,
                mobileNetworkSelectionUI: WebBrowserUI()
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
        #else
            fatalError("Currently only supports iOS.")
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

private extension Dependencies {
    func resolveNetworkInfoProvider() -> MobileNetworkInfoProvider {
        #if DEBUG
        if let mockedCarrier = options[.mockedCarrier] as? Carrier {
            return MockSIMNetworkInfoProvider(carrier: mockedCarrier)
        }
        else {
            return CTTelephonyNetworkInfo()
        }
        #else
        return CTTelephonyNetworkInfo()
        #endif
    }
}

private extension Dictionary where Key == ProjectVerifyOptionKeys, Value: Any {
    var host: ProjectVerifyNetworkConfig.Host {
        let qaFlag = self[.qaHost, or: false]
        return qaFlag ? .qa : .production
    }

    var logLevel: Log.Level {
        return self[.logLevel, or: .off]
    }
}

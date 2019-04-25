    //
//  Dependencies.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/28/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
import CoreTelephony

class Dependencies {
    let carrierInfoService: CarrierInfoServiceProtocol = CarrierInfoService(
        mobileNetworkInfoProvder: CTTelephonyNetworkInfo()
    )

    private(set) lazy var discoveryService: DiscoveryServiceProtocol = DiscoveryService(
        networkService: NetworkService(),
        configCacheService: configCacheService
    )

    private(set) lazy var mobileNetworkSelectionService: MobileNetworkSelectionServiceProtocol = {
        return MobileNetworkSelectionService(
            sdkConfig: self.sdkConfig,
            mobileNetworkSelectionUI: MobileNetworkSelectionUI()
        )
    }()

    let openIdService: OpenIdServiceProtocol = OpenIdService(
        urlResolver: XCISchemeOpenIdURLResolver()
    )
    
    let configCacheService: ConfigCacheServiceProtocol = ConfigCacheService(
        networkIdentifierCache: NetworkIdentifierCache.bundledCarrierLookup
    )

    let sdkConfig: SDKConfig

    init(sdkConfig: SDKConfig) {
        self.sdkConfig = sdkConfig
    }
}

extension Dependencies {
    var all: [Any] {
        return [
            sdkConfig,
            carrierInfoService,
            discoveryService,
            openIdService,
            configCacheService,
            mobileNetworkSelectionService,
        ]
    }
    
    func resolve<T>() -> T {
        let firstResolution = all.compactMap { $0 as? T }.first
        guard let resolved = firstResolution else {
            fatalError("attemtping to resolve a dependency that doesn't exist")
        }
        return resolved
    }
}

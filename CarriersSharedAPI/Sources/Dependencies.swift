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

    let openIdService: OpenIdServiceProtocol = OpenIdService(
        urlResolver: XCISchemeOpenIdURLResolver()
    )
    
    let configCacheService: ConfigCacheServiceProtocol = ConfigCacheService(
        networkIdentifierCache: NetworkIdentifierCache.bundledCarrierLookup
    )
}

extension Dependencies {
    var all: [Any] {
        return [
            carrierInfoService,
            discoveryService,
            openIdService,
            configCacheService
        ]
    }
    
    static func resolve<T>() -> T {
        let container = ProjectVerifyAppDelegate.shared.dependencies
        let firstResolution = container.all.compactMap { $0 as? T }.first
        guard let resolved = firstResolution else {
            fatalError("attemtping to resolve a dependency that doesn't exist")
        }
        return resolved
    }
}

//
//  CurrentSIMBrandingProvider.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 5/7/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

/// A branding provider that uses the carrier info service to inform branding decisions.
class CurrentSIMBrandingProvider: BrandingProvider {
    let configCacheService: ConfigCacheServiceProtocol
    let carrierInfoService: CarrierInfoServiceProtocol

    var branding: Branding {
        guard
            let primarySIM = carrierInfoService.primarySIM,
            let config = configCacheService.config(
                forSIMInfo: primarySIM,
                allowStaleRecords: true)
            else {
                return .default
        }

        return config.branding
    }

    init(configCacheService: ConfigCacheServiceProtocol,
         carrierInfoService: CarrierInfoServiceProtocol) {
        self.configCacheService = configCacheService
        self.carrierInfoService = carrierInfoService
    }
}

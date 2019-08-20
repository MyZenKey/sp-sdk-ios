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
    private let configCacheService: ConfigCacheServiceProtocol
    private let carrierInfoService: CarrierInfoServiceProtocol
    private(set) var observerToken: CacheObserver?

    var brandingDidChange: ((Branding) -> Void)?

    var buttonBranding: Branding {
        guard
            let primarySIM = carrierInfoService.primarySIM,
            let config = configCacheService.config(forSIMInfo: primarySIM) else {
                return .default
        }

        return config.buttonBranding
    }

    init(configCacheService: ConfigCacheServiceProtocol,
         carrierInfoService: CarrierInfoServiceProtocol) {
        self.configCacheService = configCacheService
        self.carrierInfoService = carrierInfoService

        // add an observer, on cache changes
        observerToken = configCacheService.addCacheObserver() { [weak self] simInfo in
            guard
                let sself = self,
                sself.carrierInfoService.primarySIM == simInfo else {
                    return
            }

            sself.brandingDidChange?(sself.buttonBranding)
        }
    }
}

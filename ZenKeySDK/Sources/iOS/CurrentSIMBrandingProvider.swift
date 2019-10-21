//
//  CurrentSIMBrandingProvider.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 5/7/19.
//  Copyright © 2019 XCI JV, LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

protocol BrandingProvider: AnyObject {
    var buttonBranding: Branding { get }

    var brandingDidChange: ((Branding) -> Void)? { get set }
}

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

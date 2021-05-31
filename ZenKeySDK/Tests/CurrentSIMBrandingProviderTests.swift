//
//  CurrentSIMBrandingProviderTests.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 8/20/19.
//  Copyright © 2019 ZenKey, LLC. All rights reserved.
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

import XCTest
@testable import ZenKeySDK

class CurrentSIMBrandingProviderTests: XCTestCase {
    var configCacheService: ConfigCacheServiceProtocol = CurrentSIMBrandingProviderTests.newConfigCacheService()
    var carrierInfoService: MockCarrierInfoService = CurrentSIMBrandingProviderTests.newCarrierInfoService()
    var currentSIMBrandingProvider: CurrentSIMBrandingProvider!

    let simInfo = MockSIMs.tmobile

    override func setUp() {
        super.setUp()
        createNewDependencyGraph()
        carrierInfoService.primarySIM = simInfo
    }

    func testReturnsButtonBrandingFromCachedOIDC() {
        let config = OpenIdConfig(
            authorizationEndpoint: URL.mocked,
            issuer: URL.mocked,
            linkBranding: "test mock branding",
            linkImage: URL.mocked,
            branding: URL.mocked,
            supportedScopes: ["openid", "profile", "email", "address"]
        )
        configCacheService.cacheConfig(config, forSIMInfo: simInfo)
        XCTAssertEqual(currentSIMBrandingProvider.buttonBranding, config.buttonBranding)
    }

    func testCallsBrandingDidChangeOnCacheUpdate() {
        let config = OpenIdConfig(
            authorizationEndpoint: URL.mocked,
            issuer: URL.mocked,
            linkBranding: "test mock branding",
            linkImage: URL.mocked,
            branding: URL.mocked,
            supportedScopes: ["openid", "profile", "email", "address"]
        )

        var calls = 0
        currentSIMBrandingProvider.brandingDidChange = { newBranding in
            XCTAssertEqual(newBranding, config.buttonBranding)
            calls += 1
        }

        configCacheService.cacheConfig(config, forSIMInfo: simInfo)
        XCTAssertEqual(calls, 1)
    }
}

private extension CurrentSIMBrandingProviderTests {
    static func newConfigCacheService() -> ConfigCacheService {
        return ConfigCacheService()
    }

    static func newCarrierInfoService() -> MockCarrierInfoService {
        return MockCarrierInfoService()
    }

    func createNewDependencyGraph() {
        self.configCacheService = CurrentSIMBrandingProviderTests.newConfigCacheService()
        self.carrierInfoService = CurrentSIMBrandingProviderTests.newCarrierInfoService()
        currentSIMBrandingProvider = CurrentSIMBrandingProvider(
            configCacheService: configCacheService,
            carrierInfoService: carrierInfoService
        )
    }
}

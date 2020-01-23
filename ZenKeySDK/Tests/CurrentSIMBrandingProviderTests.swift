//
//  CurrentSIMBrandingProviderTests.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 8/20/19.
//  Copyright © 2019 ZenKey, LLC. All rights reserved.
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
            branding: URL.mocked
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
            branding: URL.mocked
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

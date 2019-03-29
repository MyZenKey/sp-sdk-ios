//
//  ConfigCacheServiceTests.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 3/21/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest
@testable import CarriersSharedAPI

class ConfigCacheServiceTests: XCTestCase {
    
    var configCacheService = ConfigCacheServiceTests.newConfigCacheService()
    
    override func setUp() {
        super.setUp()
        configCacheService = ConfigCacheServiceTests.newConfigCacheService()
    }
    
    func testReturnCached() {
        let config = randomMockOIDConfig()
        let tmoSIM = MockSIMs.tmobile
        configCacheService.cacheConfig(config, forSIMInfo: tmoSIM)
        let result = configCacheService.config(forSIMInfo: tmoSIM, allowStaleRecords: false)
        XCTAssertEqual(config, result)
    }
    
    func testReturnNilOnStaleCache() {
        let config = randomMockOIDConfig()
        let tmoSIM = MockSIMs.tmobile
        configCacheService.cacheConfig(config, forSIMInfo: tmoSIM)
        
        let cacheMilliseconds = 100
        configCacheService.cacheTTL = TimeInterval(cacheMilliseconds) / 1000
        let delay = cacheMilliseconds * 2
        
        let expectation = XCTestExpectation(description: "async cache access")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(delay)) {
            let result = self.configCacheService.config(forSIMInfo: tmoSIM, allowStaleRecords: false)
            XCTAssertNil(result)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testAllowStaleRecordsReturnCached() {
        let config = randomMockOIDConfig()
        let tmoSIM = MockSIMs.tmobile
        configCacheService.cacheConfig(config, forSIMInfo: tmoSIM)

        let cacheMilliseconds = 100
        configCacheService.cacheTTL = TimeInterval(cacheMilliseconds) / 1000
        let delay = cacheMilliseconds * 2

        let expectation = XCTestExpectation(description: "async cache access")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(delay)) {
            let result = self.configCacheService.config(forSIMInfo: tmoSIM, allowStaleRecords: true)
            XCTAssertEqual(config, result)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }
    
    func testAllowStaleRecordsFallBackToBundled() {
        let tmoSIM = MockSIMs.tmobile
        let result = self.configCacheService.config(forSIMInfo: tmoSIM, allowStaleRecords: true)
        let expectedFromBundle = OpenIdConfig(
            tokenEndpoint: URL(string: "https://brass.account.t-mobile.com/tms/v3/usertoken")!,
            authorizationEndpoint: URL(string: "https://account.t-mobile.com/oauth2/v1/auth")!,
            issuer: URL(string: "https://ppd.account.t-mobile.com")!
        )
        XCTAssertEqual(result, expectedFromBundle)
    }

    func testAllowStaleRecordsReturnsNothingForUnknownSIM() {
        let unknownSIM = MockSIMs.unknown
        let result = self.configCacheService.config(forSIMInfo: unknownSIM, allowStaleRecords: true)
        XCTAssertNil(result)
    }
    
    private static func newConfigCacheService() -> ConfigCacheService {
        return ConfigCacheService(
            networkIdentifierCache: NetworkIdentifierCache.bundledCarrierLookup
        )
    }
    
    private func randomMockOIDConfig() -> OpenIdConfig {
        let value = Int.random(in: 0..<100)
        return OpenIdConfig(
            tokenEndpoint: URL(string: "xci://?foo=\(value)")!,
            authorizationEndpoint: URL(string: "xci://?bar=\(value)")!,
            issuer:  URL(string: "xci://?bah=\(value)")!
        )
    }
}

//
//  ConfigCacheServiceTests.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 3/21/19.
//  Copyright © 2019 ZenKey, LLC. All rights reserved.
//

import XCTest
@testable import ZenKeySDK

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
        let result = configCacheService.config(forSIMInfo: tmoSIM)
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
            let result = self.configCacheService.config(forSIMInfo: tmoSIM)
            XCTAssertNil(result)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testReturnsNothingForUnknownSIM() {
        let unknownSIM = MockSIMs.unknown
        let result = self.configCacheService.config(forSIMInfo: unknownSIM)
        XCTAssertNil(result)
    }

    // MARK: - Updates

    func testCacheObserverCalledWithUpdateSIMInfoForEachUpdate() {
        let cacheInfo = SIMInfo(mcc: "123", mnc: "456")
        var observerCount = 0
        let observer = self.configCacheService.addCacheObserver() { simInfo in
            XCTAssertEqual(cacheInfo, simInfo)
            observerCount += 1
        }
        let expectedCount = 5
        (0..<expectedCount).forEach() { _ in
            self.configCacheService.cacheConfig(OpenIdConfig.mocked, forSIMInfo: cacheInfo)
        }

        // this is sort of throw away - we need to retain the observer and the compliler warns for
        // unused – but it should be false any how.
        XCTAssertFalse(observer.isCancelled)
        XCTAssertEqual(observerCount, expectedCount)
    }

    func testCacheObserverCanBeCancelled() {
        var observerCount = 0
        let observer = self.configCacheService.addCacheObserver() { _ in
            observerCount += 1
        }

        self.configCacheService.cacheConfig(OpenIdConfig.mocked, forSIMInfo: MockSIMs.tmobile)
        observer.cancel()
        (0..<5).forEach() { _ in
            self.configCacheService.cacheConfig(OpenIdConfig.mocked, forSIMInfo: MockSIMs.tmobile)
        }

        // this is sort of throw away - we need to retain the observer and the compliler warns for
        // unused – but it should be false!
        XCTAssertTrue(observer.isCancelled)
        XCTAssertEqual(observerCount, 1)
    }

    func testCacheObserverWeaklyHeldByCache() {
        var observerCount = 0
        autoreleasepool {
            _ = self.configCacheService.addCacheObserver() { _ in
                observerCount += 1
            }
        }

        (0..<5).forEach() { _ in
            self.configCacheService.cacheConfig(OpenIdConfig.mocked, forSIMInfo: MockSIMs.tmobile)
        }
        XCTAssertEqual(observerCount, 0)
    }
}

private extension ConfigCacheServiceTests {
    static func newConfigCacheService() -> ConfigCacheService {
        return ConfigCacheService()
    }

    func randomMockOIDConfig() -> OpenIdConfig {
        let value = Int.random(in: 0..<100)
        return OpenIdConfig(
            authorizationEndpoint: URL(string: "xci://?bar=\(value)")!,
            issuer: URL(string: "xci://?bah=\(value)")!
        )
    }
}

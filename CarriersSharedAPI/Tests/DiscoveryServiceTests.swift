//
//  DiscoveryServiceTests.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/22/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest
@testable import CarriersSharedAPI

class MockConfigCacheService: ConfigCacheServiceProtocol {
    var implementation = MockConfigCacheService.newImplementation()
    
    var lastCacheParams: (OpenIdConfig, SIMInfo)?
    var lastConfigForParams: (SIMInfo, Bool)?

    var cacheTTL: TimeInterval {
        get { return implementation.cacheTTL }
        set {}
    }
    
    func clear() {
        implementation = MockConfigCacheService.newImplementation()
        lastCacheParams = nil
        lastConfigForParams = nil
    }
    
    func cacheConfig(_ config: OpenIdConfig, forSIMInfo simInfo: SIMInfo) {
        lastCacheParams = (config, simInfo)
        implementation.cacheConfig(config, forSIMInfo: simInfo)
    }

    func config(forSIMInfo simInfo: SIMInfo, allowStaleRecords: Bool) -> OpenIdConfig? {
        lastConfigForParams = (simInfo, allowStaleRecords)
        return implementation.config(forSIMInfo: simInfo, allowStaleRecords: allowStaleRecords)
    }
    
    private static func newImplementation() -> ConfigCacheService {
        return ConfigCacheService(
            networkIdentifierCache: NetworkIdentifierCache.bundledCarrierLookup
        )
    }
}

class DiscoveryServiceTests: XCTestCase {

    let mockNetworkService = MockNetworkService()
    let mockCarrierInfo = MockCarrierInfoService()
    let mockConfigCacheService = MockConfigCacheService()
    
    lazy var discoveryService = DiscoveryService(
        networkService: mockNetworkService,
        carrierInfoService: mockCarrierInfo,
        configCacheService: mockConfigCacheService
    )

    override func setUp() {
        super.setUp()
        mockConfigCacheService.clear()
        mockNetworkService.clear()
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.success)
    }

    func testNoSIMReturnsNoMobileNetwork() {
        mockCarrierInfo.primarySIM = nil
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig() { result in
            guard case .noMobileNetwork = result else {
                XCTFail("config expected to return noMobileNetwork")
                return
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testNoSIMDoesNotMakeNetworkRequest() {
        mockCarrierInfo.primarySIM = nil
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig() { result in
            XCTAssertNil(self.mockNetworkService.lastRequest)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testCorrectlyFormatsURL() {
        mockCarrierInfo.primarySIM = MockSIMs.unknown
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig() { _ in
            let request = self.mockNetworkService.lastRequest

            XCTAssertEqual(request?.httpMethod, "GET")
            XCTAssertEqual(request?.url?.path, "/.well-known/openid_configuration")
            XCTAssertTrue(request?.url?.query?.contains("config=false") ?? false)
            XCTAssertTrue(request?.url?.query?.contains("mcc=123") ?? false)
            XCTAssertTrue(request?.url?.query?.contains("mnc=456") ?? false)

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testUnknownCarrierEndpointErrorReturnsError() {
        mockCarrierInfo.primarySIM = MockSIMs.unknown
        let error = NSError(domain: "", code: 1, userInfo: [:])
        mockNetworkService.mockError(.networkError(error))
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig() { result in
            let resultingError = try! UnwrapAndAssertNotNil(result.errorValue)
            guard case DiscoveryServiceError.networkError = resultingError else {
                XCTFail("result expected to be networkError")
                return
            }

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testKnownCarrierEndpointErrorFallbackToBundledConfigByDefault() {
        mockCarrierInfo.primarySIM = MockSIMs.tmobile
        let error = NSError(domain: "", code: 1, userInfo: [:])
        mockNetworkService.mockError(.networkError(error))
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig() { result in
            let config = try! UnwrapAndAssertNotNil(result.carrierConfig)
            XCTAssertEqual(
                config.openIdConfig,
                OpenIdConfig(
                    tokenEndpoint: URL(string: "https://brass.account.t-mobile.com/tms/v3/usertoken")!,
                    authorizationEndpoint: URL(string: "https://account.t-mobile.com/oauth2/v1/auth")!,
                    issuer: URL(string: "https://ppd.account.t-mobile.com")!
                )
            )
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    // NOTE: this could be returns testUnknownCarrierEndpointSuccessReturnsUnknownMobileNetwork
    // in the future
    func testUnknownCarrierEndpointSuccessReturnsError() {
        mockCarrierInfo.primarySIM = MockSIMs.unknown
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.carrierNotFound)
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig() { result in
            let resultingError = try! UnwrapAndAssertNotNil(result.errorValue)
            let assertionDescription = "result expected to be issuerError"
            if case DiscoveryServiceError.issuerError = resultingError {
                XCTAssertTrue(true, assertionDescription)
            } else {
                XCTAssertTrue(false, assertionDescription)
            }

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testKnownCarrierEndpointSuccessCachesAndReturnsMockedConfig() {
        mockCarrierInfo.primarySIM = MockSIMs.tmobile
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.success)
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig() { result in
            let config = try! UnwrapAndAssertNotNil(result.carrierConfig)
            let expectedResult = OpenIdConfig(
                tokenEndpoint: URL(string: "https://brass.account.t-mobile.com/tms/v3/usertoken")!,
                authorizationEndpoint: URL(string: "xci://authorize")!,
                // TODO: re-enable this when we correct it
//                    "authorization_endpoint": "https://xcid.t-mobile.com/verify/authorize",
                issuer: URL(string: "https://brass.account.t-mobile.com")!
            )
            
            XCTAssertEqual(
                config.openIdConfig,
                expectedResult
            )
            
            let lastParams = try! UnwrapAndAssertNotNil(self.mockConfigCacheService.lastCacheParams)
            XCTAssertEqual(
                lastParams.0,
                expectedResult
            )
            
            XCTAssertEqual(
                lastParams.1,
                MockSIMs.tmobile
            )
            
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }
    
    func testKnownCarrierEndpointErrorFallbackToLastSuccessfulConfigIfAvailable() {
        mockCarrierInfo.primarySIM = MockSIMs.tmobile
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.success)
        
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig() { _ in

            let error = NSError(domain: "", code: 1, userInfo: [:])
            self.mockNetworkService.mockError(.networkError(error))
            self.discoveryService.discoverConfig() { result in
                let config = try! UnwrapAndAssertNotNil(result.carrierConfig)
                
                let expectedResult = OpenIdConfig(
                    tokenEndpoint: URL(string: "https://brass.account.t-mobile.com/tms/v3/usertoken")!,
                    authorizationEndpoint: URL(string: "xci://authorize")!,
                    // TODO: re-enable this when we correct it
//                    "authorization_endpoint": "https://xcid.t-mobile.com/verify/authorize",
                    issuer: URL(string: "https://brass.account.t-mobile.com")!
                )
                
                XCTAssertEqual(
                    config.openIdConfig,
                    expectedResult
                )
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testServiceReturnsOnMainThreadFromMainThread() {
        mockCarrierInfo.primarySIM = MockSIMs.tmobile
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.success)
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig() { _ in
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testServiceReturnsOnMainThreadFromBackgroundThread() {
        mockCarrierInfo.primarySIM = MockSIMs.tmobile
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.success)
        let expectation = XCTestExpectation(description: "async discovery")
        DispatchQueue.global().async {
            self.discoveryService.discoverConfig() { _ in
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: timeout)
    }
}

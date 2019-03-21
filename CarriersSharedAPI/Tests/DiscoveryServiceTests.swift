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
    
    var implementation = ConfigCacheService()
    
    var lastCacheParms: (OpenIdConfig, String)?
    var lastConfigForParameters: (String, Bool)?

    var cacheTTL: TimeInterval {
        get { return implementation.cacheTTL }
        set {}
    }
    
    func clear() {
        implementation = ConfigCacheService()
        lastCacheParms = nil
        lastConfigForParameters = nil
    }

    func cacheConfig(_ config: OpenIdConfig, forIdentifier identifier: String) {
        lastCacheParms = (config, identifier)
        implementation.cacheConfig(config, forIdentifier: identifier)
    }

    func config(forIdentifier identifier: String, allowStaleRecords: Bool) -> OpenIdConfig? {
        lastConfigForParameters = (identifier, allowStaleRecords)
        return implementation.config(forIdentifier: identifier, allowStaleRecords: allowStaleRecords)
    }
}

class DiscoveryServiceTests: XCTestCase {

    let tmoSIMInfo = SIMInfo(mcc: "310", mnc: "160")
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
        mockCarrierInfo.primarySIM = SIMInfo(mcc: "123", mnc: "456")
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
        mockCarrierInfo.primarySIM = SIMInfo(mcc: "123", mnc: "456")
        let error = NSError(domain: "", code: 1, userInfo: [:])
        mockNetworkService.mockError(error)
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
        mockCarrierInfo.primarySIM = tmoSIMInfo
        let error = NSError(domain: "", code: 1, userInfo: [:])
        mockNetworkService.mockError(error)
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig() { result in
            let config = try! UnwrapAndAssertNotNil(result.carrierConfig)

            XCTAssertEqual(config.carrier, Carrier.tmobile)
            XCTAssertEqual(
                config.openIdConfig,
                [
                    "scopes_supported": "openid email profile",
                    "response_types_supported": "code",
                    "userinfo_endpoint": "https://iam.msg.t-mobile.com/oidc/v1/userinfo",
                    "token_endpoint": "https://brass.account.t-mobile.com/tms/v3/usertoken",
                    "authorization_endpoint": "https://account.t-mobile.com/oauth2/v1/auth",
                    "issuer": "https://ppd.account.t-mobile.com"
                ]
            )
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    // NOTE: this could be returns testUnknownCarrierEndpointSuccessReturnsUnknownMobileNetwork
    // in the future
    func testUnknownCarrierEndpointSuccessReturnsError() {
        mockCarrierInfo.primarySIM = SIMInfo(mcc: "123", mnc: "456")
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
        mockCarrierInfo.primarySIM = tmoSIMInfo
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.success)
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig() { result in
            let config = try! UnwrapAndAssertNotNil(result.carrierConfig)
            XCTAssertEqual(config.carrier, Carrier.tmobile)
            let expectedResult = [
                "scopes_supported": "openid email profile",
                "response_types_supported": "code",
                "userinfo_endpoint": "https://iam.msg.t-mobile.com/oidc/v1/userinfo",
                "token_endpoint": "https://brass.account.t-mobile.com/tms/v3/usertoken",
                "authorization_endpoint": "xci://authorize",
                // TODO: re-enable this when we correct it
//                    "authorization_endpoint": "https://xcid.t-mobile.com/verify/authorize",
                "issuer": "https://brass.account.t-mobile.com",
            ]
            
            XCTAssertEqual(
                config.openIdConfig,
                expectedResult
            )
            
            let lastParams = try! UnwrapAndAssertNotNil(self.mockConfigCacheService.lastCacheParms)
            XCTAssertEqual(
                lastParams.0,
                expectedResult
            )
            
            XCTAssertEqual(
                lastParams.1,
                "tmo"
            )
            
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }
    
    func testKnownCarrierEndpointErrorFallbackToLastSuccessfulConfigIfAvailable() {
        mockCarrierInfo.primarySIM = tmoSIMInfo
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.success)
        
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig() { _ in

            let error = NSError(domain: "", code: 1, userInfo: [:])
            self.mockNetworkService.mockError(error)
            self.discoveryService.discoverConfig() { result in
                let config = try! UnwrapAndAssertNotNil(result.carrierConfig)
                
                XCTAssertEqual(config.carrier, Carrier.tmobile)
                XCTAssertEqual(
                    config.openIdConfig,
                    [
                        "scopes_supported": "openid email profile",
                        "response_types_supported": "code",
                        "userinfo_endpoint": "https://iam.msg.t-mobile.com/oidc/v1/userinfo",
                        "token_endpoint": "https://brass.account.t-mobile.com/tms/v3/usertoken",
                        "authorization_endpoint": "xci://authorize",
                        // TODO: re-enable this when we correct it
//                    "authorization_endpoint": "https://xcid.t-mobile.com/verify/authorize",
                        "issuer": "https://brass.account.t-mobile.com",
                    ]
                )
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: timeout)
    }
}

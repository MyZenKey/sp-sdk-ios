//
//  DiscoveryServiceTests.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/22/19.
//  Copyright © 2019 ZenKey, LLC. All rights reserved.
//

import XCTest
@testable import ZenKeySDK

// swiftlint:disable force_try
class MockConfigCacheService: ConfigCacheServiceProtocol {
    var implementation = MockConfigCacheService.newImplementation()

    var lastCacheParams: (OpenIdConfig, SIMInfo)?
    var lastConfigForParams: SIMInfo?

    var cacheTTL: TimeInterval {
        get { return implementation.cacheTTL }
        // swiftlint:disable:next unused_setter_value
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

    func config(forSIMInfo simInfo: SIMInfo) -> OpenIdConfig? {
        lastConfigForParams = simInfo
        return implementation.config(forSIMInfo: simInfo)
    }

    private static func newImplementation() -> ConfigCacheService {
        return ConfigCacheService()
    }

    func addCacheObserver(_ action: @escaping CacheObserver.Action) -> CacheObserver {
        return CacheObserver({ _ in })
    }
}

class DiscoveryServiceTests: XCTestCase {

    let mockNetworkService = MockNetworkService()
    let mockCarrierInfo = MockCarrierInfoService()
    let mockConfigCacheService = MockConfigCacheService()

    let mockClientId = "mockclientid"
    let mockRedirectScheme = "xci"

    lazy var discoveryService = DiscoveryService(
        sdkConfig: SDKConfig(clientId: mockClientId, redirectScheme: mockRedirectScheme),
        hostConfig: ZenKeyNetworkConfig(host: .production),
        networkService: mockNetworkService,
        configCacheService: mockConfigCacheService
    )

    override func setUp() {
        super.setUp()
        mockConfigCacheService.clear()
        mockNetworkService.clear()
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.success)
    }

    func testCorrectlyFormatsURLWithMCCMNC() {
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig(forSIMInfo: MockSIMs.unknown) { _ in
            let request = self.mockNetworkService.lastRequest

            XCTAssertEqual(request?.httpMethod, "GET")
            XCTAssertEqual(request?.url?.scheme, "https")
            XCTAssertEqual(request?.url?.host, ZenKeyNetworkConfig.Host.production.rawValue)
            XCTAssertEqual(request?.url?.path, "/.well-known/openid_configuration")
            AssertHasQueryItemPair(url: request?.url, key: "mccmnc", value: "123456")
            AssertHasQueryItemPair(url: request?.url, key: "client_id", value: self.mockClientId)
            AssertHasQueryItemPair(url: request?.url, key: "sdk_version", value: VERSION)

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testCorrectlyFormatsURLWithoutMCCMNC() {
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig(forSIMInfo: nil) { _ in
            let request = self.mockNetworkService.lastRequest

            XCTAssertEqual(request?.httpMethod, "GET")
            XCTAssertEqual(request?.url?.scheme, "https")
            XCTAssertEqual(request?.url?.host, ZenKeyNetworkConfig.Host.production.rawValue)
            XCTAssertEqual(request?.url?.path, "/.well-known/openid_configuration")
            AssertHasQueryItemPair(url: request?.url, key: "client_id", value: self.mockClientId)
            AssertDoesntContainQueryItem(url: request?.url, key: "mccmnc")

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testCorrectlyFormatsURLWithPromptValue() {
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig(forSIMInfo: nil, prompt: true) { _ in
            let request = self.mockNetworkService.lastRequest

            XCTAssertEqual(request?.httpMethod, "GET")
            XCTAssertEqual(request?.url?.scheme, "https")
            XCTAssertEqual(request?.url?.host, ZenKeyNetworkConfig.Host.production.rawValue)
            XCTAssertEqual(request?.url?.path, "/.well-known/openid_configuration")
            AssertHasQueryItemPair(url: request?.url, key: "client_id", value: self.mockClientId)
            AssertHasQueryItemPair(url: request?.url, key: "prompt", value: "true")
            AssertDoesntContainQueryItem(url: request?.url, key: "mccmnc")

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testUnknownCarrierEndpointErrorReturnsError() {
        let error = NSError(domain: "", code: 1, userInfo: [:])
        mockNetworkService.mockError(.networkError(error))
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig(forSIMInfo: MockSIMs.unknown) { result in
            let resultingError = try! UnwrapAndAssertNotNil(result.errorValue)
            guard case DiscoveryServiceError.networkError = resultingError else {
                XCTFail("result expected to be networkError")
                return
            }

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testKnownCarrierEndpointErrorReturnsError() {
        let error = NSError(domain: "", code: 1, userInfo: [:])
        mockNetworkService.mockError(.networkError(error))
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig(forSIMInfo: MockSIMs.tmobile) { result in
            defer { expectation.fulfill() }
            guard case .error = result else {
                XCTFail("expected error")
                return
            }
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testKnownCarrierEndpointErrorFallbackToCacheIfValid() {
        let error = NSError(domain: "", code: 1, userInfo: [:])
        mockNetworkService.mockError(.networkError(error))
        let expectedConfig = OpenIdConfig(
            authorizationEndpoint: URL.mocked,
            issuer: URL.mocked
        )
        mockConfigCacheService.cacheConfig(
            expectedConfig,
            forSIMInfo: MockSIMs.tmobile
        )

        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig(forSIMInfo: MockSIMs.tmobile) { result in
            defer { expectation.fulfill() }
            guard case .knownMobileNetwork(let config) = result else {
                XCTFail("expected cached result")
                return
            }

            XCTAssertEqual(config.openIdConfig, expectedConfig)
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testUnknownCarrierEndpointSuccessReturnsDiscoveryUI() {
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.carrierNotFound)
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig(forSIMInfo: MockSIMs.unknown) { result in

            defer { expectation.fulfill() }
            guard case .unknownMobileNetwork(let redirect) = result else {
                XCTFail("expected a redirect to discovery ui")
                return
            }

            XCTAssertEqual(redirect.redirectURI.absoluteString, "https://app.xcijv.com/ui/discovery-ui")

        }
        wait(for: [expectation], timeout: timeout)
    }

    func testKnownCarrierEndpointSuccessCachesAndReturnsMockedConfigForPassedSIMInfo() {
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.success)
        let expectation = XCTestExpectation(description: "async discovery")
        let passedSIMInfo = SIMInfo(mcc: "123", mnc: "456")
        discoveryService.discoverConfig(forSIMInfo: passedSIMInfo) { result in
            let config = try! UnwrapAndAssertNotNil(result.carrierConfig)
            let expectedResult = CarrierConfig(
                simInfo: MockSIMs.tmobile,
                openIdConfig: OpenIdConfig(
                    authorizationEndpoint: URL(string: "https://xcid.t-mobile.com/verify/authorize")!,
                    issuer: URL(string: "https://brass.account.t-mobile.com")!
                )
            )

            XCTAssertEqual(
                config,
                expectedResult
            )

            let lastParams = try! UnwrapAndAssertNotNil(self.mockConfigCacheService.lastCacheParams)
            XCTAssertEqual(
                lastParams.0,
                expectedResult.openIdConfig
            )

            XCTAssertEqual(
                lastParams.1,
                passedSIMInfo
            )

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testKnownCarrierEndpointCachesAndReturnsDiscoveredMCCMNCEvenIfNoInfoPassed() {
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.success)
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig(forSIMInfo: nil) { result in
            let config = try! UnwrapAndAssertNotNil(result.carrierConfig)
            let expectedResult = CarrierConfig(
                simInfo: MockSIMs.tmobile,
                openIdConfig: OpenIdConfig(
                    authorizationEndpoint: URL(string: "https://xcid.t-mobile.com/verify/authorize")!,
                    issuer: URL(string: "https://brass.account.t-mobile.com")!
                )
            )

            XCTAssertEqual(
                config,
                expectedResult
            )

            let lastParams = try! UnwrapAndAssertNotNil(self.mockConfigCacheService.lastCacheParams)
            XCTAssertEqual(
                lastParams.0,
                expectedResult.openIdConfig
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
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.success)

        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig(forSIMInfo: MockSIMs.tmobile) { _ in

            let error = NSError(domain: "", code: 1, userInfo: [:])
            self.mockNetworkService.mockError(.networkError(error))
            self.discoveryService.discoverConfig(forSIMInfo: MockSIMs.tmobile) { result in
                let config = try! UnwrapAndAssertNotNil(result.carrierConfig)

                let expectedResult = OpenIdConfig(
                    authorizationEndpoint: URL(string: "https://xcid.t-mobile.com/verify/authorize")!,
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
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.success)
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig(forSIMInfo: MockSIMs.tmobile) { _ in
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testServiceReturnsOnMainThreadFromBackgroundThread() {
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.success)
        let expectation = XCTestExpectation(description: "async discovery")
        DispatchQueue.global().async {
            self.discoveryService.discoverConfig(forSIMInfo: MockSIMs.tmobile) { _ in
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: timeout)
    }
}

// MARK: - test utils

extension DiscoveryServiceResult {
    var carrierConfig: CarrierConfig? {
        switch self {
        case .knownMobileNetwork(let config):
            return config
        default:
            return nil
        }
    }

    var errorValue: DiscoveryServiceError? {
        switch self {
        case .error(let error):
            return error
        default:
            return nil
        }
    }
}
// swiftlint:enable force_try

//
//  DiscoveryServiceTests.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/22/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest
@testable import CarriersSharedAPI

// swiftlint:disable force_try
class MockConfigCacheService: ConfigCacheServiceProtocol {
    var implementation = MockConfigCacheService.newImplementation()

    var lastCacheParams: (OpenIdConfig, SIMInfo)?
    var lastConfigForParams: (SIMInfo, Bool)?

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

    let mockClientId = "mockclientid"
    let mockRedirectScheme = "xci"

    lazy var discoveryService = DiscoveryService(
        sdkConfig: SDKConfig(clientId: mockClientId, redirectScheme: mockRedirectScheme),
        hostConfig: ProjectVerifyNetworkConfig(host: .production),
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
            XCTAssertEqual(request?.url?.host, ProjectVerifyNetworkConfig.Host.production.rawValue)
            XCTAssertEqual(request?.url?.path, "/.well-known/openid_configuration")
            XCTAssertTrue(request?.url?.query?.contains("mccmnc=123456") ?? false)
            XCTAssertTrue(request?.url?.query?.contains("client_id=\(self.mockClientId)") ?? false)

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
            XCTAssertEqual(request?.url?.host, ProjectVerifyNetworkConfig.Host.production.rawValue)
            XCTAssertEqual(request?.url?.path, "/.well-known/openid_configuration")
            XCTAssertFalse(request?.url?.query?.contains("mccmnc") ?? false)
            XCTAssertTrue(request?.url?.query?.contains("client_id=\(self.mockClientId)") ?? false)

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
            XCTAssertEqual(request?.url?.host, ProjectVerifyNetworkConfig.Host.production.rawValue)
            XCTAssertEqual(request?.url?.path, "/.well-known/openid_configuration")
            XCTAssertFalse(request?.url?.query?.contains("mccmnc") ?? false)
            XCTAssertTrue(request?.url?.query?.contains("client_id=\(self.mockClientId)") ?? false)
            XCTAssertTrue(request?.url?.query?.contains("prompt=true") ?? false)

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

    func testKnownCarrierEndpointErrorFallbackToBundledConfigByDefault() {
        let error = NSError(domain: "", code: 1, userInfo: [:])
        mockNetworkService.mockError(.networkError(error))
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig(forSIMInfo: MockSIMs.tmobile) { result in
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

    func testUnknownCarrierEndpointSuccessReturnsDiscoveryUI() {
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.carrierNotFound)
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig(forSIMInfo: MockSIMs.unknown) { result in

            defer { expectation.fulfill() }
            guard case .unknownMobileNetwork(let redirect) = result else {
                XCTFail("expected a redirect to discovery ui")
                return
            }

            XCTAssertEqual(redirect.redirectURI.absoluteString, "http://app.xcijv.com/ui/discovery-ui")

        }
        wait(for: [expectation], timeout: timeout)
    }

    func testKnownCarrierEndpointSuccessCachesAndReturnsMockedConfig() {
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.success)
        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig(forSIMInfo: MockSIMs.tmobile) { result in
            let config = try! UnwrapAndAssertNotNil(result.carrierConfig)
            let expectedResult = OpenIdConfig(
                tokenEndpoint: URL(string: "https://brass.account.t-mobile.com/tms/v3/usertoken")!,
                authorizationEndpoint: URL(string: "https://xcid.t-mobile.com/verify/authorize")!,
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
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.success)

        let expectation = XCTestExpectation(description: "async discovery")
        discoveryService.discoverConfig(forSIMInfo: MockSIMs.tmobile) { _ in

            let error = NSError(domain: "", code: 1, userInfo: [:])
            self.mockNetworkService.mockError(.networkError(error))
            self.discoveryService.discoverConfig(forSIMInfo: MockSIMs.tmobile) { result in
                let config = try! UnwrapAndAssertNotNil(result.carrierConfig)

                let expectedResult = OpenIdConfig(
                    tokenEndpoint: URL(string: "https://brass.account.t-mobile.com/tms/v3/usertoken")!,
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

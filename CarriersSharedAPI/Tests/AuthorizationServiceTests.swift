//
//  AuthorizationServiceTests.swift
//  AppAuth
//
//  Created by Adam Tierney on 2/26/19.
//

import XCTest
import AppAuth
@testable import CarriersSharedAPI

class MockOpenIdService: OpenIdServiceProtocol {
    var lastConfig: OpenIdAuthorizationConfig?
    var lastViewController: UIViewController?
    var mockResponse: AuthorizationResult = AuthorizationResult.code(
        AuthorizedResponse(code: "abc123", mcc: "123", mnc: "456")
    )

    func clear() {
        lastConfig = nil
        lastViewController = nil
    }

    func authorize(
        fromViewController viewController: UIViewController,
        authorizationConfig: OpenIdAuthorizationConfig,
        completion: @escaping AuthorizationCompletion
    ) {

        self.lastViewController = viewController
        self.lastConfig = authorizationConfig

        DispatchQueue.main.async {
            completion(self.mockResponse)
        }
    }

    var authorizationInProgress: Bool = false

    func cancelCurrentAuthorizationSession() { }

    func resolve(url: URL) -> Bool { return true }

    func concludeAuthorizationFlow(result: AuthorizationResult) { }
}

class AuthorizationServiceTests: XCTestCase {

    let mockNetworkService = MockNetworkService()
    let mockCarrierInfo = MockCarrierInfoService()
    let mockOpenIdService = MockOpenIdService()

    let mockSDKConfig = SDKConfig(
        clientId: "mockClient",
        redirectScheme: "pvmockCLient://"
    )

    let networkIdentifierCache =  NetworkIdentifierCache.bundledCarrierLookup
    lazy var discoveryService = DiscoveryService(
        networkService: mockNetworkService,
        configCacheService: ConfigCacheService(networkIdentifierCache: networkIdentifierCache)
    )

    lazy var authorizationService = AuthorizationService(
        sdkConfig: mockSDKConfig,
        discoveryService: discoveryService,
        openIdService: mockOpenIdService,
        carrierInfoService: mockCarrierInfo,
        // TODO: test this
        mobileNetworkSelectionService: MobileNetworkSelectionService()
    )

    let scopes: [Scope] = [.address, .address, .email]

    override func setUp() {
        super.setUp()
        mockOpenIdService.clear()
    }

    func testPassesViewControllerToOpenIdService() {
        mockCarrierInfo.primarySIM = MockSIMs.unknown
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.success)

        let expectedController = UIViewController()

        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.connectWithProjectVerify(
            scopes: self.scopes,
            fromViewController: expectedController) { result in
                XCTAssertEqual(self.mockOpenIdService.lastViewController, expectedController)
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testPassesCorrectScopeStringsToOpenIdService() {
        mockCarrierInfo.primarySIM = MockSIMs.unknown
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.success)

        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.connectWithProjectVerify(
            scopes: self.scopes,
            fromViewController: UIViewController()) { result in
                XCTAssertEqual(self.mockOpenIdService.lastConfig?.formattedScopes, "openid address email")
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    // TODO: test these at Auth Service level
    //    func testNoSIMReturnsNoMobileNetwork() {
    //        mockCarrierInfo.primarySIM = nil
    //        let expectation = XCTestExpectation(description: "async discovery")
    //        discoveryService.discoverConfig() { result in
    //            guard case .noMobileNetwork = result else {
    //                XCTFail("config expected to return noMobileNetwork")
    //                return
    //            }
    //            expectation.fulfill()
    //        }
    //        wait(for: [expectation], timeout: timeout)
    //    }

    //    func testNoSIMDoesNotMakeNetworkRequest() {
    //        mockCarrierInfo.primarySIM = nil
    //        let expectation = XCTestExpectation(description: "async discovery")
    //        discoveryService.discoverConfig() { result in
    //            XCTAssertNil(self.mockNetworkService.lastRequest)
    //            expectation.fulfill()
    //        }
    //        wait(for: [expectation], timeout: timeout)
    //    }
}

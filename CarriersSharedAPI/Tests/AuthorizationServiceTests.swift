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
        authorizationConifg: OpenIdAuthorizationConfig,
        completion: @escaping AuthorizationCompletion
    ) {

        self.lastViewController = viewController
        self.lastConfig = authorizationConifg

        DispatchQueue.main.async {
            completion(self.mockResponse)
        }
    }

    var authorizationInProgress: Bool = false

    func cancelCurrentAuthorizationSession() { }

    func concludeAuthorizationFlow(url: URL) { }

    func concludeAuthorizationFlow(result: AuthorizationResult) { }
}

class AuthorizationServiceTests: XCTestCase {

    let mockNetworkService = MockNetworkService()
    let mockCarrierInfo = MockCarrierInfoService()
    let mockOpenIdService = MockOpenIdService()

    let mockSDKConfig = SDKConfig(
        clientId: "mockClient",
        redirectURL: URL(string: "pvmockCLient://")!
    )

    let networkIdentifierCache =  NetworkIdentifierCache.bundledCarrierLookup
    lazy var discoveryService = DiscoveryService(
        networkService: mockNetworkService,
        carrierInfoService: mockCarrierInfo,
        configCacheService: ConfigCacheService(networkIdentifierCache: networkIdentifierCache)
    )

    lazy var authorizationService = AuthorizationService(
        sdkConfig: mockSDKConfig,
        discoveryService: discoveryService,
        openIdService: mockOpenIdService
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
}

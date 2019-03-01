//
//  AuthorizationServiceTests.swift
//  AppAuth
//
//  Created by Adam Tierney on 2/26/19.
//

import XCTest
import AppAuth
@testable import CarriersSharedAPI

class MockAuthorizationStateManager: AuthorizationStateManager {
    var currentAuthorizationFlow: OIDExternalUserAgentSession?
}

class MockOpenIdService: OpenIdServiceProtocol {
    var lastConfig: OpenIdAuthorizationConfig?
    var lastViewController: UIViewController?
    var lastStateManager: AuthorizationStateManager?
    var mockResponse: AuthorizationResult = AuthorizationResult.code(
        AuthorizedResponse(code: "abc123", mcc: "123", mnc: "456")
    )

    func clear() {
        lastConfig = nil
        lastViewController = nil
        lastStateManager = nil
    }

    func authorize(
        fromViewController viewController: UIViewController,
        stateManager: AuthorizationStateManager,
        authorizationConifg: OpenIdAuthorizationConfig,
        completion: @escaping AuthorizationCompletion) {

        self.lastViewController = viewController
        self.lastStateManager = stateManager
        self.lastConfig = authorizationConifg

        DispatchQueue.main.async {
            completion(self.mockResponse)
        }
    }
}

class AuthorizationServiceTests: XCTestCase {

    let mockAuthorizationStateManager = MockAuthorizationStateManager()
    let mockNetworkService = MockNetworkService()
    let mockCarrierInfo = MockCarrierInfoService()
    let mockOpenIdService = MockOpenIdService()

    let mockSDKConfig = SDKConfig(
        clientId: "mockClient",
        redirectURL: URL(string: "pvmockCLient://")!
    )

    lazy var discoveryService = DiscoveryService(
        networkService: mockNetworkService,
        carrierInfoService: mockCarrierInfo
    )

    lazy var authorizationService = AuthorizationService(
        authorizationStateManager: mockAuthorizationStateManager,
        sdkConfig: mockSDKConfig,
        discoveryService: discoveryService,
        openIdService: mockOpenIdService
    )

    let scopes: [Scope] = [.address, .address, .email]

    override func setUp() {
        super.setUp()
        mockOpenIdService.clear()
    }

    func testPassesStateMangerToOpenIdService() {
        mockCarrierInfo.primarySIM = SIMInfo(mcc: "123", mnc: "456")
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.success)

        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.connectWithProjectVerify(
            scopes: self.scopes,
            fromViewController: UIViewController()) { result in
                XCTAssertTrue(self.mockOpenIdService.lastStateManager === self.mockAuthorizationStateManager)
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testPassesViewControllerToOpenIdService() {
        mockCarrierInfo.primarySIM = SIMInfo(mcc: "123", mnc: "456")
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
        mockCarrierInfo.primarySIM = SIMInfo(mcc: "123", mnc: "456")
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

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

    let mockAuthoizationStateManager = MockAuthorizationStateManager()
    var lastConfig: OpenIdAuthorizationConfig?
    var mockResponse: AuthorizationResult = AuthorizationResult.code("abc123")

    func authorize(
        fromViewController viewController: UIViewController,
        stateManager: AuthorizationStateManager,
        authorizationConifg: OpenIdAuthorizationConfig,
        completion: AuthorizationCompletion?) {

        self.lastConfig = authorizationConifg

        DispatchQueue.main.async {

        }
    }
}

class AuthorizationServiceTests: XCTestCase {
    let mockNetworkService = MockNetworkService()
    let mockCarrierInfo = MockCarrierInfoService()
    lazy var discoveryService = DiscoveryService(
        networkService: mockNetworkService,
        carrierInfoService: mockCarrierInfo
    )

//    lazy var authorizationService = AuthorizationService(
//        authorizationStateManager: mockAuthoizationStateManager,
//        sdkConfig: ,
//        discoveryService: ,
//        openIdService:
//    )

    override func setUp() {
        super.setUp()
        mockNetworkService.mockJSON(DiscoveryConfigMockPayloads.success)
    }

    func testPassesCorrectScopeStringsToOpenIdService() {

    }
}

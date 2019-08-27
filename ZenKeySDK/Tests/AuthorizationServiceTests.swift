//
//  AuthorizationServiceTests.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/26/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest
@testable import ZenKeySDK

class AuthorizationServiceTests: XCTestCase {

    let mockNetworkService = MockNetworkService()
    let mockCarrierInfo = MockCarrierInfoService()
    let mockOpenIdService = MockOpenIdService()
    let mockDiscoveryService = MockDiscoveryService()
    let mockNetworkSelectionService = MockMobileNetworkSelectionService()

    let mockSDKConfig = SDKConfig(
        clientId: "mockClient",
        redirectScheme: "pvmockCLient://"
    )

    lazy var authorizationService = authorizationServiceFactory()

    let scopes: [Scope] = [.openid, .address, .address, .email]

    override func setUp() {
        super.setUp()
        mockOpenIdService.clear()
        mockDiscoveryService.clear()
        mockNetworkSelectionService.clear()
    }

    func authorizationServiceFactory(
        // swiftlint:disable:next line_length
        stateGenerator: @escaping () -> String? = RandomStringGenerator.generateStateSuitableString) -> AuthorizationServiceIOS {
        return AuthorizationServiceIOS(
            sdkConfig: mockSDKConfig,
            discoveryService: mockDiscoveryService,
            openIdService: mockOpenIdService,
            carrierInfoService: mockCarrierInfo,
            mobileNetworkSelectionService: mockNetworkSelectionService,
            stateGenerator: stateGenerator
        )
    }
}

extension AuthorizationServiceTests {

    func testMultipleCallsCancelsPreviousCalls() {
        mockCarrierInfo.primarySIM = MockSIMs.att
        mockDiscoveryService.responseQueue.mockResponses = [
            .knownMobileNetwork(MockDiscoveryService.mockSuccess),
            .knownMobileNetwork(MockDiscoveryService.mockSuccess),
            .knownMobileNetwork(MockDiscoveryService.mockSuccess),
        ]
        let expectationA = XCTestExpectation(description: "async authorization one")
        let expectationB = XCTestExpectation(description: "async authorization two")
        let expectationC = XCTestExpectation(description: "async authorization three")

        let controller = UIViewController()
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: controller,
            correlationId: "foo") { result in
                defer { expectationA.fulfill() }
                guard case .cancelled = result else {
                    XCTFail("expected to cancel")
                    return
                }
        }

        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: controller,
            correlationId: "bar") { result in
                defer { expectationB.fulfill() }
                guard case .cancelled = result else {
                    XCTFail("expected to cancel")
                    return
                }
        }

        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: controller,
            correlationId: "bah") { result in
                defer { expectationC.fulfill() }
                guard case .code = result else {
                    XCTFail("expected success")
                    return
                }
        }

        wait(for: [expectationA, expectationB, expectationC], timeout: timeout)
    }
}

// MARK: - OpenIdService

extension AuthorizationServiceTests {

    // MARK: Inputs

    func testPassesDefaultScopeToOpenIdService() {
        mockCarrierInfo.primarySIM = MockSIMs.unknown
        let expectedController = UIViewController()
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.authorize(fromViewController: expectedController) { _ in
                XCTAssertEqual(self.mockOpenIdService.lastParameters?.formattedScopes, "openid")
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testPassesViewControllerAndScopeToOpenIdService() {
        mockCarrierInfo.primarySIM = MockSIMs.unknown
        let expectedController = UIViewController()
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: expectedController) { _ in
                XCTAssertEqual(self.mockOpenIdService.lastViewController, expectedController)
                XCTAssertEqual(self.mockOpenIdService.lastParameters?.formattedScopes, "address email openid")
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testGeneratesStateIfNonePassed() {
        mockCarrierInfo.primarySIM = MockSIMs.unknown
        let expectedController = UIViewController()
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: expectedController) { _ in
                XCTAssertNotNil(self.mockOpenIdService.lastParameters?.state)
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testPassesOptionalParameters() {
        mockCarrierInfo.primarySIM = MockSIMs.unknown
        let expectedController = UIViewController()
        let expectation = XCTestExpectation(description: "async authorization")

        let expected = OpenIdAuthorizationRequest.Parameters(
            clientId: mockSDKConfig.clientId,
            redirectURL: mockSDKConfig.redirectURL,
            formattedScopes: "address email openid",
            state: "foo",
            nonce: "bar",
            acrValues: [.aal2],
            prompt: .consent,
            correlationId: "bar",
            context: "biz",
            loginHintToken: nil
        )

        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: expectedController,
            acrValues: expected.acrValues,
            state: expected.state,
            correlationId: expected.correlationId,
            context: expected.context,
            prompt: expected.prompt,
            nonce: expected.nonce) { _ in
                XCTAssertEqual(self.mockOpenIdService.lastViewController, expectedController)
                XCTAssertEqual(self.mockOpenIdService.lastParameters, expected)
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    // MARK: Outputs

    func testOpenIdSuccess() {
        mockCarrierInfo.primarySIM = MockSIMs.tmobile
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: UIViewController()) { result in
                defer { expectation.fulfill() }
                guard case .code(let payload) = result else {
                    XCTFail("expected a successful response")
                    return
                }
                let mockedResponse = MockOpenIdService.mockSuccess
                XCTAssertEqual(payload.code, mockedResponse.code)
                XCTAssertEqual(payload.mcc, mockedResponse.mcc)
                XCTAssertEqual(payload.mnc, mockedResponse.mnc)
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testOpenIdError() {
        mockCarrierInfo.primarySIM = MockSIMs.tmobile
        let mockNetowrkError = NSError.mocked
        let mockError: OpenIdServiceError = .urlResolverError(mockNetowrkError)
        mockOpenIdService.mockResponse = .error(mockError)
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: UIViewController()) { result in
                defer { expectation.fulfill() }
                guard
                    case .error(let error) = result else {
                    XCTFail("expected an error response")
                    return
                }
                XCTAssertEqual(error.code, SDKErrorCode.networkError.rawValue)
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testOpenIdCancelled() {
        mockCarrierInfo.primarySIM = MockSIMs.tmobile
        mockOpenIdService.mockResponse = .cancelled
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: UIViewController()) { result in
                defer { expectation.fulfill() }
                guard case .cancelled = result else {
                    XCTFail("expected a cancelled response")
                    return
                }
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testStateGenerationError() {
        mockCarrierInfo.primarySIM = MockSIMs.tmobile
        mockOpenIdService.mockResponse = .cancelled

        let failingStateGeneratorAuthService = authorizationServiceFactory(
            stateGenerator: { return nil }
        )

        let expectation = XCTestExpectation(description: "async authorization")
        failingStateGeneratorAuthService.authorize(
            scopes: self.scopes,
            fromViewController: UIViewController()) { result in
                defer { expectation.fulfill() }
                guard case .error(let error) = result else {
                    XCTFail("expected a cancelled response")
                    return
                }

                XCTAssertEqual(error, RequestStateError.generationFailed.asAuthorizationError)
        }
        wait(for: [expectation], timeout: timeout)
    }
}

// MARK: - URL Hanlding

extension AuthorizationServiceTests {
    func testDoesntHandleURLsByDefault() {
        let url = URL.mocked
        let result = authorizationService.resolve(url: url)
        XCTAssertNil(mockNetworkSelectionService.lastURL)
        XCTAssertNil(mockOpenIdService.lastURL)
        XCTAssertFalse(result)
    }

    func testURLConcludesMobileNetworkSelectionStep() {
        let url = URL.mocked
        mockNetworkSelectionService.holdCompletionUntilURL = true
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: UIViewController()) { _ in
                expectation.fulfill()
        }

        mockNetworkSelectionService.didCallRequestUserNetworkHook = {
            let result = self.authorizationService.resolve(url: url)
            XCTAssertNotNil(self.mockNetworkSelectionService.lastURL)
            XCTAssertNil(self.mockOpenIdService.lastURL)
            XCTAssertTrue(result)
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testURLDoesntConcludesAuthorizationStep() {
        let url = URL.mocked
        mockOpenIdService.holdCompletionUntilURL = true

        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: UIViewController()) { _ in
                expectation.fulfill()
        }

        mockOpenIdService.didCallAuthorizeHook = {
            let result = self.authorizationService.resolve(url: url)
            XCTAssertNil(self.mockNetworkSelectionService.lastURL)
            XCTAssertNotNil(self.mockOpenIdService.lastURL)
            XCTAssertTrue(result)

        }

        wait(for: [expectation], timeout: timeout)
    }
}

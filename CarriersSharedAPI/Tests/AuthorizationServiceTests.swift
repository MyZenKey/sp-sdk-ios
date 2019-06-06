//
//  AuthorizationServiceTests.swift
//  AppAuth
//
//  Created by Adam Tierney on 2/26/19.
//

import XCTest
import AppAuth
@testable import CarriersSharedAPI

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

    let networkIdentifierCache =  NetworkIdentifierCache.bundledCarrierLookup

    lazy var authorizationService = AuthorizationServiceIOS(
        sdkConfig: mockSDKConfig,
        discoveryService: mockDiscoveryService,
        openIdService: mockOpenIdService,
        carrierInfoService: mockCarrierInfo,
        mobileNetworkSelectionService: mockNetworkSelectionService
    )

    let scopes: [Scope] = [.address, .address, .email]

    override func setUp() {
        super.setUp()
        mockOpenIdService.clear()
        mockDiscoveryService.clear()
        mockNetworkSelectionService.clear()
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

// MARK: - DiscoveryService

extension AuthorizationServiceTests {

    // MARK: Inputs

    func testDiscoveryServiceReceivesSIMWhenPresent() {
        mockCarrierInfo.primarySIM = MockSIMs.att
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: UIViewController()) { _ in }
        XCTAssertEqual(mockDiscoveryService.lastSIMInfo, MockSIMs.att)
        XCTAssertNotNil(mockDiscoveryService.lastCompletion)
    }

    func testDiscoveryCallsIfNoSIMPresent() {
        mockCarrierInfo.primarySIM = nil
        let expectedViewController = UIViewController()
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: expectedViewController) { _ in }

        XCTAssertNil(mockDiscoveryService.lastSIMInfo)
        XCTAssertNotNil(mockDiscoveryService.lastCompletion)
    }

    // MARK: Outputs

    func testDiscoverSuccess() {
        mockCarrierInfo.primarySIM = MockSIMs.tmobile
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: UIViewController()) { result in
                guard case .code(let payload) = result else {
                    XCTFail("expected a successful response")
                    return
                }
                let mockedResponse = MockOpenIdService.mockSuccess
                XCTAssertEqual(payload.code, mockedResponse.code)
                XCTAssertEqual(payload.mcc, mockedResponse.mcc)
                XCTAssertEqual(payload.mnc, mockedResponse.mnc)
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testDiscoverError() {
        mockCarrierInfo.primarySIM = MockSIMs.tmobile
        let mockError: DiscoveryServiceError = .networkError(.networkError(NSError.mocked))
        mockDiscoveryService.responseQueue.mockResponses = [ .error(mockError) ]
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: UIViewController()) { result in
                guard case .error(let error) = result else {
                    XCTFail("expected an error response")
                    return
                }
                XCTAssertEqual(error.code, SDKErrorCode.networkError.rawValue)
                XCTAssertEqual(error.description, "a network error occurred")
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }
}

// MARK: - OpenIdService

extension AuthorizationServiceTests {

    // MARK: Inputs

    func testPassesViewControllerAndScopeToOpenIdService() {
        mockCarrierInfo.primarySIM = MockSIMs.unknown
        let expectedController = UIViewController()
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: expectedController) { _ in
                XCTAssertEqual(self.mockOpenIdService.lastViewController, expectedController)
                XCTAssertEqual(self.mockOpenIdService.lastParameters?.formattedScopes, "openid address email")
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

        let expected = OpenIdAuthorizationParameters(
            clientId: mockSDKConfig.clientId,
            redirectURL: mockSDKConfig.redirectURL(forRoute: .authorize),
            formattedScopes: "openid address email",
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
                guard case .code(let payload) = result else {
                    XCTFail("expected a successful response")
                    return
                }
                let mockedResponse = MockOpenIdService.mockSuccess
                XCTAssertEqual(payload.code, mockedResponse.code)
                XCTAssertEqual(payload.mcc, mockedResponse.mcc)
                XCTAssertEqual(payload.mnc, mockedResponse.mnc)
                expectation.fulfill()
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
                guard
                    case .error(let error) = result else {
                    XCTFail("expected an error response")
                    return
                }
                XCTAssertEqual(error.code, SDKErrorCode.networkError.rawValue)
                expectation.fulfill()
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
                guard case .cancelled = result else {
                    XCTFail("expected a cancelled response")
                    return
                }
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }
}

// MARK: - Secondary Device Flow

extension AuthorizationServiceTests {

    // MARK: Inputs

    func testSIMPresentBypassesSecondaryDeviceFlow() {
        mockCarrierInfo.primarySIM = MockSIMs.tmobile
        let expectation = XCTestExpectation(description: "async authorization")
        let expectedViewController = UIViewController()
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: expectedViewController) { _ in
                XCTAssertNil(self.mockNetworkSelectionService.lastViewController)
                XCTAssertNil(self.mockNetworkSelectionService.lastCompletion)
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testUnknownCarrierPassesOffToSecondaryDeviceFlow() {
        mockSecondaryDeviceFlow()
        let expectation = XCTestExpectation(description: "async authorization")
        let expectedViewController = UIViewController()
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: expectedViewController) { _ in
                XCTAssertEqual(
                    self.mockNetworkSelectionService.lastViewController, expectedViewController
                )
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    // MARK: Outputs

    func testSecondaryDeviceFlowSuccess() {
        mockSecondaryDeviceFlow()
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: UIViewController()) { result in
                guard case .code(let payload) = result else {
                    XCTFail("expected a successful response")
                    return
                }
                let mockedResponse = MockOpenIdService.mockSuccess
                XCTAssertEqual(payload.code, mockedResponse.code)
                XCTAssertEqual(payload.mcc, mockedResponse.mcc)
                XCTAssertEqual(payload.mnc, mockedResponse.mnc)
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testSecondaryDeviceFlowError() {
        mockSecondaryDeviceFlow()
        let expectedError: MobileNetworkSelectionError = .invalidMCCMNC
        mockNetworkSelectionService.mockResponse = .error(expectedError)
        let expectation = XCTestExpectation(description: "async authorization")
        let expectedViewController = UIViewController()
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: expectedViewController) { result in
                guard case .error(let error) = result else {
                    XCTFail("expected an error response")
                    return
                }

                XCTAssertEqual(error.code, SDKErrorCode.invalidParameter.rawValue)
                XCTAssertEqual(error.description, "mccmnc paramter is misformatted")
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testSecondaryDeviceFlowCancel() {
        mockSecondaryDeviceFlow()
        mockNetworkSelectionService.mockResponse = .cancelled
        let expectation = XCTestExpectation(description: "async authorization")
        let expectedViewController = UIViewController()
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: expectedViewController) { result in
                defer { expectation.fulfill() }
                guard case .cancelled = result else {
                    XCTFail("expected an cancelled response")
                    return
                }
        }
        wait(for: [expectation], timeout: timeout)
    }
}

// MARK: - Helpers

private extension AuthorizationServiceTests {
    func mockSecondaryDeviceFlow() {
        mockCarrierInfo.primarySIM = nil
        mockDiscoveryService.responseQueue.mockResponses = [
            .unknownMobileNetwork(MockDiscoveryService.mockRedirect),
            .knownMobileNetwork(MockDiscoveryService.mockSuccess),
        ]
    }
}

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
    static let mockSuccess = AuthorizedResponse(code: "abc123", mcc: "123", mnc: "456")
    var lastConfig: OpenIdAuthorizationConfig?
    var lastViewController: UIViewController?
    var mockResponse: AuthorizationResult = AuthorizationResult.code(
        MockOpenIdService.mockSuccess
    )

    func clear() {
        lastConfig = nil
        lastViewController = nil
        mockResponse = AuthorizationResult.code(
            MockOpenIdService.mockSuccess
        )
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

class MockMobileNetworkSelectionService: MobileNetworkSelectionServiceProtocol {
    static let mockSuccess: SIMInfo = MockSIMs.tmobile

    var mockResponse: MobileNetworkSelectionUIResult = .networkInfo(MockMobileNetworkSelectionService.mockSuccess)
    var lastViewController: UIViewController?
    var lastCompletion: MobileNetworkSelectionCompletion?

    func clear() {
        lastViewController = nil
        lastCompletion = nil
    }

    func requestUserNetworkSelection(
        fromCurrentViewController viewController: UIViewController,
        completion: @escaping MobileNetworkSelectionCompletion) {

        self.lastViewController = viewController
        self.lastCompletion = completion

        DispatchQueue.main.async {
            completion(self.mockResponse)
        }
    }

    func resolve(url: URL) -> Bool { return true }
}

class MockDiscoveryService: DiscoveryServiceProtocol {

    static let mockSuccess = CarrierConfig(
        simInfo: MockSIMs.tmobile,
        openIdConfig: OpenIdConfig(
            tokenEndpoint: URL.mocked,
            authorizationEndpoint: URL.mocked,
            issuer: URL.mocked
        )
    )
    
    var mockResponse: DiscoveryServiceResult = .knownMobileNetwork(MockDiscoveryService.mockSuccess)
    var lastSIMInfo: SIMInfo?
    var lastCompletion: DiscoveryServiceCompletion?

    func clear() {
        lastSIMInfo = nil
        lastCompletion = nil
        mockResponse = .knownMobileNetwork(MockDiscoveryService.mockSuccess)
    }

    func discoverConfig(
        forSIMInfo simInfo: SIMInfo,
        completion: @escaping DiscoveryServiceCompletion) {
        lastSIMInfo = simInfo
        lastCompletion = completion

        DispatchQueue.main.async {
            completion(self.mockResponse)
        }
    }
}

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

    lazy var authorizationService = AuthorizationService(
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

    // MARK: - DiscoveryService Outputs

    func testDiscoverSuccess() {
        mockCarrierInfo.primarySIM = MockSIMs.tmobile
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.connectWithProjectVerify(
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
        mockDiscoveryService.mockResponse = .error(mockError)
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.connectWithProjectVerify(
            scopes: self.scopes,
            fromViewController: UIViewController()) { result in
                guard case .error(let error) = result else {
                    XCTFail("expected an error response")
                    return
                }
                guard
                    let discoveryError = error as? DiscoveryServiceError,
                    case DiscoveryServiceError.networkError = discoveryError
                    else {
                        XCTFail("expected an error \(error) to match \(mockError)")
                        return
                }
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    // MARK: - Connection with OpenIdService

    func testPassesViewControllerAndScopeToOpenIdService() {
        mockCarrierInfo.primarySIM = MockSIMs.unknown
        let expectedController = UIViewController()
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.connectWithProjectVerify(
            scopes: self.scopes,
            fromViewController: expectedController) { result in
                XCTAssertEqual(self.mockOpenIdService.lastViewController, expectedController)
                XCTAssertEqual(self.mockOpenIdService.lastConfig?.formattedScopes, "openid address email")
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    // MARK: - Outputs of OpenIdService

    func testOpenIdSuccess() {
        mockCarrierInfo.primarySIM = MockSIMs.tmobile
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.connectWithProjectVerify(
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
        let mockError = NSError.mocked
        mockOpenIdService.mockResponse = .error(mockError)
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.connectWithProjectVerify(
            scopes: self.scopes,
            fromViewController: UIViewController()) { result in
                guard case .error(let error) = result else {
                    XCTFail("expected an error response")
                    return
                }
                XCTAssertEqual(error as NSError, mockError)
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testOpenIdCancelled() {
        mockCarrierInfo.primarySIM = MockSIMs.tmobile
        mockOpenIdService.mockResponse = .cancelled
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.connectWithProjectVerify(
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

    // MARK: - Secondary Device Flow

    func testSIMPresentBypassesSecondaryDeviceFlow() {
        mockCarrierInfo.primarySIM = MockSIMs.tmobile
        let expectation = XCTestExpectation(description: "async authorization")
        let expectedViewController = UIViewController()
        authorizationService.connectWithProjectVerify(
            scopes: self.scopes,
            fromViewController: expectedViewController) { _ in
                XCTAssertNil(self.mockNetworkSelectionService.lastViewController)
                XCTAssertNil(self.mockNetworkSelectionService.lastCompletion)
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testNoSIMPassesOffToSecondaryDeviceFlow() {
        mockCarrierInfo.primarySIM = nil
        let expectation = XCTestExpectation(description: "async authorization")
        let expectedViewController = UIViewController()
        authorizationService.connectWithProjectVerify(
            scopes: self.scopes,
            fromViewController: expectedViewController) { _ in
                XCTAssertEqual(
                    self.mockNetworkSelectionService.lastViewController, expectedViewController
                )
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testSecondaryDeviceFlowSuccess() {
        mockCarrierInfo.primarySIM = nil
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.connectWithProjectVerify(
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
        mockCarrierInfo.primarySIM = nil
        let expectedError: MobileNetworkSelectionUIError = .invalidMCCMNC
        mockNetworkSelectionService.mockResponse = .error(expectedError)
        let expectation = XCTestExpectation(description: "async authorization")
        let expectedViewController = UIViewController()
        authorizationService.connectWithProjectVerify(
            scopes: self.scopes,
            fromViewController: expectedViewController) { result in
                guard case .error(let error) = result else {
                    XCTFail("expected an error response")
                    return
                }
                guard
                    let networkSelectionError = error as? MobileNetworkSelectionUIError,
                    case MobileNetworkSelectionUIError.invalidMCCMNC = networkSelectionError
                    else {
                        XCTFail("expected an error \(error) to match \(expectedError)")
                        return
                    }
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testSecondaryDeviceFlowCancel() {
        mockCarrierInfo.primarySIM = nil
        mockNetworkSelectionService.mockResponse = .cancelled
        let expectation = XCTestExpectation(description: "async authorization")
        let expectedViewController = UIViewController()
        authorizationService.connectWithProjectVerify(
            scopes: self.scopes,
            fromViewController: expectedViewController) { result in
                guard case .cancelled = result else {
                    XCTFail("expected an cancelled response")
                    return
                }
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }
}

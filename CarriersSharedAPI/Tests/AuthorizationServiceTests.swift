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
    var mockResponse: OpenIdServiceResult = .code(
        MockOpenIdService.mockSuccess
    )

    func clear() {
        lastConfig = nil
        lastViewController = nil
        mockResponse = .code(
            MockOpenIdService.mockSuccess
        )
    }

    func authorize(
        fromViewController viewController: UIViewController,
        authorizationConfig: OpenIdAuthorizationConfig,
        completion: @escaping OpenIdServiceCompletion
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

    static let mockSuccess: MobileNetworkSelectionResponse = MobileNetworkSelectionResponse(
        simInfo: MockSIMs.tmobile,
        loginHintToken: nil
    )

    var mockResponse: MobileNetworkSelectionResult = .networkInfo(MockMobileNetworkSelectionService.mockSuccess)

    var lastResource: URL?
    var lastViewController: UIViewController?
    var lastCompletion: MobileNetworkSelectionCompletion?

    func clear() {
        lastResource = nil
        lastViewController = nil
        lastCompletion = nil
    }

    func requestUserNetworkSelection(
        fromResource resource: URL,
        fromCurrentViewController viewController: UIViewController,
        completion: @escaping MobileNetworkSelectionCompletion) {

        self.lastResource = resource
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

    static let mockRedirect = IssuerResponse.Redirect(
        error: "foo", redirectURI: URL.mocked
    )

    var lastSIMInfo: SIMInfo?
    var lastCompletion: DiscoveryServiceCompletion?

    /// FIFO responses
    var mockResponses: [DiscoveryServiceResult] = [
        .knownMobileNetwork(MockDiscoveryService.mockSuccess),
    ]

    func clear() {
        lastSIMInfo = nil
        lastCompletion = nil
        mockResponses = [
            .knownMobileNetwork(MockDiscoveryService.mockSuccess),
        ]
    }

    func discoverConfig(
        forSIMInfo simInfo: SIMInfo?,
        completion: @escaping DiscoveryServiceCompletion) {
        lastSIMInfo = simInfo
        lastCompletion = completion

        DispatchQueue.main.async {
            guard let result = self.mockResponses.first else {
                XCTFail("not enough reponses configured")
                return
            }
            self.mockResponses = Array(self.mockResponses.dropFirst())
            completion(result)
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

    // MARK: - DiscoveryService Inputs

    func testDiscoveryServiceRecivesSIMWhenPresent() {
        mockCarrierInfo.primarySIM = MockSIMs.att
        authorizationService.connectWithProjectVerify(
            scopes: self.scopes,
            fromViewController: UIViewController()) { _ in }
        XCTAssertEqual(mockDiscoveryService.lastSIMInfo, MockSIMs.att)
        XCTAssertNotNil(mockDiscoveryService.lastCompletion)
    }

    func testDiscoveryCallsIfNoSIMPresent() {
        mockCarrierInfo.primarySIM = nil
        let expectedViewController = UIViewController()
        authorizationService.connectWithProjectVerify(
            scopes: self.scopes,
            fromViewController: expectedViewController) { _ in }

        XCTAssertNil(mockDiscoveryService.lastSIMInfo)
        XCTAssertNotNil(mockDiscoveryService.lastCompletion)
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
        mockDiscoveryService.mockResponses = [ .error(mockError) ]
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.connectWithProjectVerify(
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

    // MARK: - OpenIdService Inputs

    func testPassesViewControllerAndScopeToOpenIdService() {
        mockCarrierInfo.primarySIM = MockSIMs.unknown
        let expectedController = UIViewController()
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.connectWithProjectVerify(
            scopes: self.scopes,
            fromViewController: expectedController) { _ in
                XCTAssertEqual(self.mockOpenIdService.lastViewController, expectedController)
                XCTAssertEqual(self.mockOpenIdService.lastConfig?.formattedScopes, "openid address email")
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    // MARK: - OpenIdService Outputs

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
        let mockNetowrkError = NSError.mocked
        let mockError: OpenIdServiceError = .urlResolverError(mockNetowrkError)
        mockOpenIdService.mockResponse = .error(mockError)
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.connectWithProjectVerify(
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

    // MARK: - Secondary Device Flow Inputs

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

    func testUnknownCarrierPassesOffToSecondaryDeviceFlow() {
        mockSecondaryDeviceFlow()
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

    // MARK: - Secondary Device Flow Outputs

    func testSecondaryDeviceFlowSuccess() {
        mockSecondaryDeviceFlow()
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
        mockSecondaryDeviceFlow()
        let expectedError: MobileNetworkSelectionError = .invalidMCCMNC
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

private extension AuthorizationServiceTests {
    func mockSecondaryDeviceFlow() {
        mockCarrierInfo.primarySIM = nil
        mockDiscoveryService.mockResponses = [
            .unknownMobileNetwork(MockDiscoveryService.mockRedirect),
            .knownMobileNetwork(MockDiscoveryService.mockSuccess),
        ]
    }
}

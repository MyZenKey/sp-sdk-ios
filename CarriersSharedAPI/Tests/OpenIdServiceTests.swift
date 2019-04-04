
//
//  OpenIdServiceTests.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 3/6/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest
import AppAuth
@testable import CarriersSharedAPI

class MockURLResolver: OpenIdURLResolverProtocol {

    var lastStorage: OpenIdExternalSessionStateStorage?
    var lastRequest: OIDAuthorizationRequest?
    var lastViewController: UIViewController?
    var lastConfig: OpenIdAuthorizationConfig?
    var lastCompletion: OpenIdURLResolverCompletion?

    func clear() {
        lastStorage = nil
        lastRequest = nil
        lastViewController = nil
        lastConfig = nil
        lastCompletion = nil
    }

    func resolve(
        request: OIDAuthorizationRequest,
        usingStorage storage: OpenIdExternalSessionStateStorage,
        fromViewController viewController: UIViewController,
        authorizationConfig: OpenIdAuthorizationConfig,
        completion: @escaping OpenIdURLResolverCompletion) {
        lastStorage = storage
        lastRequest = request
        lastViewController = viewController
        lastConfig = authorizationConfig
        lastCompletion = completion
    }

    func performCCIDAuthorization(
        request: OIDAuthorizationRequest,
        storage: OpenIdExternalSessionStateStorage,
        authorizationConfig: OpenIdAuthorizationConfig,
        completion: @escaping OpenIdURLResolverCompletion) {

    }
}

class OpenIdServiceTests: XCTestCase {

    static let mockConfig = OpenIdAuthorizationConfig(
        simInfo: MockSIMs.unknown,
        clientId: "foo",
        authorizationEndpoint: URL(string: "http://rightpoint.com")!,
        tokenEndpoint: URL(string: "http://rightpoint.com")!,
        formattedScopes: "openid",
        redirectURL: URL(string: "testapp://authorize")!,
        state: "bar"
    )

    var mockURLResolver = MockURLResolver()
    lazy var openIdService: OpenIdService = {
        OpenIdService(urlResolver: mockURLResolver)
    }()

    override func setUp() {
        super.setUp()
        mockURLResolver.clear()
        openIdService.cancelCurrentAuthorizationSession()
    }

    func testInitialState() {
        XCTAssertFalse(openIdService.authorizationInProgress)
    }

    func testPassesParametersToURLResolver() {
        let testViewContorller = UIViewController()
        let completion: AuthorizationCompletion = { _ in }
        openIdService.authorize(
            fromViewController: testViewContorller,
            authorizationConifg: OpenIdServiceTests.mockConfig,
            completion: completion)

        let passedViewController = try? UnwrapAndAssertNotNil(mockURLResolver.lastViewController)
        let passedConfig = try? UnwrapAndAssertNotNil(mockURLResolver.lastConfig)

        XCTAssertEqual(passedViewController, testViewContorller)
        XCTAssertEqual(passedConfig, OpenIdServiceTests.mockConfig)

        guard case .inProgress(let request, _, _, let storage) = openIdService.state else {
            XCTFail("expected in progress state")
            return
        }

        let passedRequest = try? UnwrapAndAssertNotNil(mockURLResolver.lastRequest)
        let passedStorage = try? UnwrapAndAssertNotNil(mockURLResolver.lastStorage)
        XCTAssertEqual(passedRequest, request)
        XCTAssertTrue(passedStorage === storage)
    }

    func testAuthorizationInProgress() {
        openIdService.authorize(
            fromViewController: UIViewController(),
            authorizationConifg: OpenIdServiceTests.mockConfig,
            completion: { _ in })
        XCTAssertTrue(openIdService.authorizationInProgress)
    }

    func testCancelOperation() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: UIViewController(),
            authorizationConifg: OpenIdServiceTests.mockConfig) { result in
                defer { expectation.fulfill() }
                guard case .cancelled = result else {
                    XCTFail("expected to be cancelled")
                    return
                }
        }
        openIdService.cancelCurrentAuthorizationSession()
        wait(for: [expectation], timeout: timeout)
    }

    func testConcludeWithURLSuccess() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: UIViewController(),
            authorizationConifg: OpenIdServiceTests.mockConfig) { result in
                defer { expectation.fulfill() }
                guard case .code(let response) = result else {
                    XCTFail("expected to be cancelled")
                    return
                }

                XCTAssertEqual(response.code, "TESTCODE")
                XCTAssertEqual(response.mcc, "123")
                XCTAssertEqual(response.mnc, "456")
        }

        let urlString = "testapp://authorize?code=TESTCODE&state=bar"
        openIdService.concludeAuthorizationFlow(url: URL(string: urlString)!)
        wait(for: [expectation], timeout: timeout)
    }

    func testConcludeWithURLNoRequestInProgressError() {
        let urlString = "testapp://authorize?code=TESTCODE&state=bar"
        openIdService.concludeAuthorizationFlow(url: URL(string: urlString)!)
    }

    func testConcludeWithURLStateMismatchError() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: UIViewController(),
            authorizationConifg: OpenIdServiceTests.mockConfig) { result in
                guard
                    case .error(let error) = result,
                    case AuthorizationError.stateMismatch = error else {
                    XCTFail("expected to be state mismatch error")
                    return
                }
                expectation.fulfill()
        }

        let urlString = "testapp://authorize?code=TESTCODE&state=BIZ"
        openIdService.concludeAuthorizationFlow(url: URL(string: urlString)!)
        wait(for: [expectation], timeout: timeout)
    }

    func testConcludeWithURLMissingAuthCodeError() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: UIViewController(),
            authorizationConifg: OpenIdServiceTests.mockConfig) { result in
                guard
                    case .error(let error) = result,
                    case AuthorizationError.missingAuthCode = error else {
                        XCTFail("expected to be state mismatch error")
                        return
                }
                expectation.fulfill()
        }

        let urlString = "testapp://authorize?state=bar"
        openIdService.concludeAuthorizationFlow(url: URL(string: urlString)!)
        wait(for: [expectation], timeout: timeout)
    }

    // MARK: - URL passed errors

    func testParseURLErrorIdentifierOnly() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: UIViewController(),
            authorizationConifg: OpenIdServiceTests.mockConfig) { result in
                guard
                    case .error(let error) = result,
                    case AuthorizationError.oauth(let code, let description) = error else {
                        XCTFail("expected to be an oauth error")
                        return
                }

                XCTAssertEqual(code, OAuthErrorCode.invalidRequest)
                XCTAssertNil(description)
                expectation.fulfill()
        }

        let urlString = "testapp://authorize?error=\(OAuthErrorCode.invalidRequest.rawValue)"
        openIdService.concludeAuthorizationFlow(url: URL(string: urlString)!)
        wait(for: [expectation], timeout: timeout)
    }

    func testParseURLErrorIdentifierAndDescription() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: UIViewController(),
            authorizationConifg: OpenIdServiceTests.mockConfig) { result in
                guard
                    case .error(let error) = result,
                    case AuthorizationError.oauth(let code, let description) = error else {
                        XCTFail("expected to be an oauth error")
                        return
                }

                XCTAssertEqual(code, OAuthErrorCode.invalidRequest)
                XCTAssertEqual(description, "foo")
                expectation.fulfill()
        }

        let urlString = "testapp://authorize?error=\(OAuthErrorCode.invalidRequest.rawValue)&error_description=foo"
        openIdService.concludeAuthorizationFlow(url: URL(string: urlString)!)
        wait(for: [expectation], timeout: timeout)
    }

    func testErrorValueForOAuthErrorIdentifierOnly() {
        let expectedError = OAuthErrorCode.invalidRequest
        let error = OpenIdService.errorValue(
            fromIdentifier: expectedError.rawValue,
            description: nil
        )

        guard
            case AuthorizationError.oauth(let code, let description) = error else {
                XCTFail("expected to be an oauth error")
                return
        }

        XCTAssertEqual(code, expectedError)
        XCTAssertNil(description)
    }

    func testErrorValueForOAuthErrorAndDescription() {
        let expectedError = OAuthErrorCode.invalidRequest
        let expectedDescription = "foo"
        let error = OpenIdService.errorValue(
            fromIdentifier: expectedError.rawValue,
            description: expectedDescription
        )

        guard
            case AuthorizationError.oauth(let code, let description) = error else {
                XCTFail("expected to be an oauth error")
                return
        }

        XCTAssertEqual(code, expectedError)
        XCTAssertEqual(description, expectedDescription)
    }

    func testErrorValueForOpenIdErrorIdentifierOnly() {
        let expectedError = OpenIdErrorCode.loginRequired
        let error = OpenIdService.errorValue(
            fromIdentifier: expectedError.rawValue,
            description: nil
        )

        guard
            case AuthorizationError.openId(let code, let description) = error else {
                XCTFail("expected to be an oauth error")
                return
        }

        XCTAssertEqual(code, expectedError)
        XCTAssertNil(description)
    }

    func testErrorValueForOpenIdErrorAndDescription() {
        let expectedError = OpenIdErrorCode.loginRequired
        let expectedDescription = "foo"
        let error = OpenIdService.errorValue(
            fromIdentifier: expectedError.rawValue,
            description: expectedDescription
        )

        guard
            case AuthorizationError.openId(let code, let description) = error else {
                XCTFail("expected to be an oauth error")
                return
        }

        XCTAssertEqual(code, expectedError)
        XCTAssertEqual(description, expectedDescription)
    }

    func testErrorValueForProjectVerifyErrorIdentifierOnly() {
        let expectedError = ProjectVerifyErrorCode.authenticationTimedOut
        let error = OpenIdService.errorValue(
            fromIdentifier: expectedError.rawValue,
            description: nil
        )

        guard
            case AuthorizationError.projectVerify(let code, let description) = error else {
                XCTFail("expected to be an oauth error")
                return
        }

        XCTAssertEqual(code, expectedError)
        XCTAssertNil(description)
    }

    func testErrorValueForProjectVerifyErrorAndDescription() {
        let expectedError = ProjectVerifyErrorCode.authenticationTimedOut
        let expectedDescription = "foo"
        let error = OpenIdService.errorValue(
            fromIdentifier: expectedError.rawValue,
            description: expectedDescription
        )

        guard
            case AuthorizationError.projectVerify(let code, let description) = error else {
                XCTFail("expected to be an oauth error")
                return
        }

        XCTAssertEqual(code, expectedError)
        XCTAssertEqual(description, expectedDescription)
    }

    func testErrorValueForUnknownErrorIdentifierOnly() {
        let expectedError = "invalid_error_id"
        let error = OpenIdService.errorValue(
            fromIdentifier: expectedError,
            description: nil
        )

        guard
            case AuthorizationError.unknown(let code, let description) = error else {
                XCTFail("expected to be an oauth error")
                return
        }

        XCTAssertEqual(code, expectedError)
        XCTAssertNil(description)
    }

    func testErrorValueForUnknownErrorAndDescription() {
        let expectedError = "invalid_error_id"
        let expectedDescription = "foo"
        let error = OpenIdService.errorValue(
            fromIdentifier: expectedError,
            description: expectedDescription
        )

        guard
            case AuthorizationError.unknown(let code, let description) = error else {
                XCTFail("expected to be an oauth error")
                return
        }

        XCTAssertEqual(code, expectedError)
        XCTAssertEqual(description, expectedDescription)
    }
    
    // MARK: - Redundant Requests
    
    func testDuplicateRequestsCancelsFirst() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: UIViewController(),
            authorizationConifg: OpenIdServiceTests.mockConfig) { result in
                defer { expectation.fulfill() }
                guard case .cancelled = result else {
                    XCTFail("expected a cancelled result")
                    return
                }
        }
        openIdService.authorize(
            fromViewController: UIViewController(),
            authorizationConifg: OpenIdServiceTests.mockConfig) { _ in }
        
        wait(for: [expectation], timeout: timeout)
    }
}

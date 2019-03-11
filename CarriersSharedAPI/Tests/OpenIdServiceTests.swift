
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

    var lastRequest: OIDAuthorizationRequest?
    var lastViewController: UIViewController?
    var lastConfig: OpenIdAuthorizationConfig?
    var lastCompletion: OpenIdURLResolverCompletion?

    func clear() {
        lastRequest = nil
        lastViewController = nil
        lastConfig = nil
        lastCompletion = nil
    }

    func resolve(
        withRequest request: OIDAuthorizationRequest,
        fromViewController viewController: UIViewController,
        authorizationConfig: OpenIdAuthorizationConfig,
        completion: @escaping OpenIdURLResolverCompletion) {
        lastRequest = request
        lastViewController = viewController
        lastConfig = authorizationConfig
        lastCompletion = completion
    }

    func performCCIDAuthorization(
        request: OIDAuthorizationRequest,
        authorizationConfig: OpenIdAuthorizationConfig,
        completion: @escaping OpenIdURLResolverCompletion) {

    }
}

class OpenIdServiceTests: XCTestCase {

    static let mockConfig = OpenIdAuthorizationConfig(
        simInfo: SIMInfo(mcc: "123", mnc: "456"),
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

        guard case .inProgress(let request, _, _) = openIdService.state else {
            XCTFail("expected in progress state")
            return
        }

        let passedRequest = try? UnwrapAndAssertNotNil(mockURLResolver.lastRequest)
        XCTAssertEqual(passedRequest, request)
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
                guard case .cancelled = result else {
                    XCTFail("expected to be cancelled")
                    return
                }

                expectation.fulfill()
        }
        openIdService.cancelCurrentAuthorizationSession()
        wait(for: [expectation], timeout: timeout)
    }

    func testConcludeWithURLSuccess() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: UIViewController(),
            authorizationConifg: OpenIdServiceTests.mockConfig) { result in
                guard case .code(let response) = result else {
                    XCTFail("expected to be cancelled")
                    return
                }

                XCTAssertEqual(response.code, "TESTCODE")
                XCTAssertEqual(response.mcc, "123")
                XCTAssertEqual(response.mnc, "456")

                expectation.fulfill()
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
                    case OpenIdError.stateMismatch = error else {
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
                    case OpenIdError.missingAuthCode = error else {
                        XCTFail("expected to be state mismatch error")
                        return
                }
                expectation.fulfill()
        }

        let urlString = "testapp://authorize?state=bar"
        openIdService.concludeAuthorizationFlow(url: URL(string: urlString)!)
        wait(for: [expectation], timeout: timeout)
    }
}

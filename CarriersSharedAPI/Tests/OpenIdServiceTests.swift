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
    var lastParameters: OpenIdAuthorizationParameters?
    var lastCompletion: OpenIdURLResolverCompletion?

    func clear() {
        lastStorage = nil
        lastRequest = nil
        lastViewController = nil
        lastParameters = nil
        lastCompletion = nil
    }

    func resolve(
        request: OIDAuthorizationRequest,
        usingStorage storage: OpenIdExternalSessionStateStorage,
        fromViewController viewController: UIViewController,
        authorizationParameters: OpenIdAuthorizationParameters,
        completion: @escaping OpenIdURLResolverCompletion) {
        lastStorage = storage
        lastRequest = request
        lastViewController = viewController
        lastParameters = authorizationParameters
        lastCompletion = completion
    }

    func performCCIDAuthorization(
        request: OIDAuthorizationRequest,
        storage: OpenIdExternalSessionStateStorage,
        authorizationParameters: OpenIdAuthorizationParameters,
        completion: @escaping OpenIdURLResolverCompletion) {

    }
}

class OpenIdServiceTests: XCTestCase {
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
        let completion: OpenIdServiceCompletion = { _ in }
        openIdService.authorize(
            fromViewController: testViewContorller,
            carrierConfig: OpenIdServiceTests.mockCarrierConfig,
            authorizationParameters: OpenIdServiceTests.mockParameters,
            completion: completion
        )

        let passedViewController = try? UnwrapAndAssertNotNil(mockURLResolver.lastViewController)
        let passedParameters = try? UnwrapAndAssertNotNil(mockURLResolver.lastParameters)

        XCTAssertEqual(passedViewController, testViewContorller)
        XCTAssertEqual(passedParameters, OpenIdServiceTests.mockParameters)

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
            carrierConfig: OpenIdServiceTests.mockCarrierConfig,
            authorizationParameters: OpenIdServiceTests.mockParameters,
            completion: { _ in })
        XCTAssertTrue(openIdService.authorizationInProgress)
    }

    func testCancelOperation() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: UIViewController(),
            carrierConfig: OpenIdServiceTests.mockCarrierConfig,
            authorizationParameters: OpenIdServiceTests.mockParameters) { result in
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
            carrierConfig: OpenIdServiceTests.mockCarrierConfig,
            authorizationParameters: OpenIdServiceTests.mockParameters) { result in
                defer { expectation.fulfill() }
                guard case .code(let response) = result else {
                    XCTFail("expected to be cancelled")
                    return
                }

                XCTAssertEqual(response.code, "TESTCODE")
                XCTAssertEqual(response.mcc, MockSIMs.tmobile.mcc)
                XCTAssertEqual(response.mnc, MockSIMs.tmobile.mnc)
        }

        let urlString = "testapp://projectverify/authorize?code=TESTCODE&state=bar"
        let handled = openIdService.resolve(url: URL(string: urlString)!)
        XCTAssertTrue(handled)
        wait(for: [expectation], timeout: timeout)
    }

    func testConcludeWithURLNoRequestInProgressError() {
        let urlString = "testapp://projectverify/authorize?code=TESTCODE&state=bar"
        let handled = openIdService.resolve(url: URL(string: urlString)!)
        XCTAssertFalse(handled)
    }

    func testConcludeWithURLStateMismatchError() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: UIViewController(),
            carrierConfig: OpenIdServiceTests.mockCarrierConfig,
            authorizationParameters: OpenIdServiceTests.mockParameters) { result in
                defer { expectation.fulfill() }
                guard
                    case .error(let error) = result,
                    case .urlResponseError(let responseError) = error,
                    case .stateMismatch = responseError else {
                    XCTFail("expected to be state mismatch error")
                    return
                }
        }

        let urlString = "testapp://projectverify/authorize?code=TESTCODE&state=BIZ"
        let handled = openIdService.resolve(url: URL(string: urlString)!)
        XCTAssertTrue(handled)
        wait(for: [expectation], timeout: timeout)
    }

    func testConcludeWithURLMissingAuthCodeError() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: UIViewController(),
            carrierConfig: OpenIdServiceTests.mockCarrierConfig,
            authorizationParameters: OpenIdServiceTests.mockParameters) { result in
                defer { expectation.fulfill() }
                guard
                    case .error(let error) = result,
                    case .urlResponseError(let responseError) = error,
                    case .missingParameter(let param) = responseError else {
                        XCTFail("expected to be state mismatch error")
                        return
                }

                XCTAssertEqual(param, "code")
        }

        let urlString = "testapp://projectverify/authorize?state=bar"
        let handled = openIdService.resolve(url: URL(string: urlString)!)
        XCTAssertTrue(handled)
        wait(for: [expectation], timeout: timeout)
    }

    // MARK: - URL passed errors

    func testParseURLErrorIdentifierOnly() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: UIViewController(),
            carrierConfig: OpenIdServiceTests.mockCarrierConfig,
            authorizationParameters: OpenIdServiceTests.mockParameters) { result in
                defer { expectation.fulfill() }
                guard
                    case .error(let error) = result,
                    case .urlResponseError(let responseError) = error,
                    case .errorResponse(let code, let desc) = responseError else {
                        XCTFail("expected to be an oauth error")
                        return
                }

                XCTAssertEqual(code, OAuthErrorCode.invalidRequest.rawValue)
                XCTAssertNil(desc)
        }

        let urlString = "testapp://projectverify/authorize?state=bar&error=\(OAuthErrorCode.invalidRequest.rawValue)"
        let handled = openIdService.resolve(url: URL(string: urlString)!)
        XCTAssertTrue(handled)
        wait(for: [expectation], timeout: timeout)
    }

    func testParseURLErrorIdentifierAndDescription() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: UIViewController(),
            carrierConfig: OpenIdServiceTests.mockCarrierConfig,
            authorizationParameters: OpenIdServiceTests.mockParameters) { result in
                defer { expectation.fulfill() }
                guard
                    case .error(let error) = result,
                    case .urlResponseError(let responseError) = error,
                    case .errorResponse(let code, let desc) = responseError  else {
                        XCTFail("expected to be an oauth error")
                        return
                }

                XCTAssertEqual(code, OAuthErrorCode.invalidRequest.rawValue)
                XCTAssertEqual(desc, "foo")
        }

        // swiftlint:disable:next line_length
        let urlString = "testapp://projectverify/authorize?state=bar&error=\(OAuthErrorCode.invalidRequest.rawValue)&error_description=foo"
        let handled = openIdService.resolve(url: URL(string: urlString)!)
        XCTAssertTrue(handled)
        wait(for: [expectation], timeout: timeout)
    }

    // MARK: - Redundant Requests

    func testDuplicateRequestsCancelsFirst() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: UIViewController(),
            carrierConfig: OpenIdServiceTests.mockCarrierConfig,
            authorizationParameters: OpenIdServiceTests.mockParameters) { result in
                defer { expectation.fulfill() }
                guard case .cancelled = result else {
                    XCTFail("expected a cancelled result")
                    return
                }
        }
        openIdService.authorize(
            fromViewController: UIViewController(),
            carrierConfig: OpenIdServiceTests.mockCarrierConfig,
            authorizationParameters: OpenIdServiceTests.mockParameters) { _ in }

        wait(for: [expectation], timeout: timeout)
    }

}

extension OpenIdServiceTests {
    static let mockParameters = OpenIdAuthorizationParameters(
        clientId: "foo",
        redirectURL: URL(string: "testapp://projectverify/authorize")!,
        formattedScopes: "openid",
        state: "bar",
        nonce: nil,
        acrValues: [.aal1],
        prompt: nil,
        correlationId: nil,
        context: nil,
        loginHintToken: nil
    )

    static let mockCarrierConfig = CarrierConfig(
        simInfo: MockSIMs.tmobile,
        openIdConfig: OpenIdConfig(
            tokenEndpoint: URL.mocked,
            authorizationEndpoint: URL.mocked,
            issuer: URL.mocked
        )
    )
}

// MARK: - Request Building

class AuthorizationURLBuilderTests: XCTestCase {

    func testBuildsCorrectRequestFromConfig() {
        let parameters = OpenIdAuthorizationParameters(
            clientId: "1234",
            redirectURL: URL.mocked,
            formattedScopes: "openid profile email",
            state: nil,
            nonce: nil,
            acrValues: nil,
            prompt: nil,
            correlationId: nil,
            context: nil,
            loginHintToken: nil
        )

        let serviceConfig = OIDServiceConfiguration(
            authorizationEndpoint: URL.mocked,
            tokenEndpoint: URL.mocked
        )

        let request = OpenIdService.createAuthorizationRequest(
            openIdServiceConfiguration: serviceConfig,
            authorizationParameters: parameters
        )

        let url: URL = request.authorizationRequestURL()
        let expectdURL = URL(
            // swiftlint:disable:next line_length
            string: "https://rightpoint.com?client_id=1234&scope=openid%20profile%20email&redirect_uri=https://rightpoint.com&state=\(parameters.state!)&nonce=\(parameters.nonce!)&response_type=code"
        )!

        XCTAssertEqual(url, expectdURL)
    }

    func testBuildsCorrectRequestWithOptionalParameters() {
        let parameters = OpenIdAuthorizationParameters(
            clientId: "1234",
            redirectURL: URL.mocked,
            formattedScopes: "openid profile email",
            state: "foo",
            nonce: "bar",
            acrValues: [.aal1],
            prompt: .consent,
            correlationId: "fizz",
            context: "buzz",
            loginHintToken: "boo"
        )
        let serviceConfig = OIDServiceConfiguration(
            authorizationEndpoint: URL.mocked,
            tokenEndpoint: URL.mocked
        )
        let request = OpenIdService.createAuthorizationRequest(
            openIdServiceConfiguration: serviceConfig,
            authorizationParameters: parameters
        )

        let url: URL = request.authorizationRequestURL()
        let expectdURL = URL(
            // swiftlint:disable:next line_length
            string: "https://rightpoint.com?correlation_id=fizz&prompt=consent&response_type=code&nonce=bar&scope=openid%20profile%20email&context=buzz&acr_values=aal1&login_hint_token=boo&redirect_uri=https://rightpoint.com&client_id=1234&state=foo"
        )!
        XCTAssertEqual(url, expectdURL)
    }
}

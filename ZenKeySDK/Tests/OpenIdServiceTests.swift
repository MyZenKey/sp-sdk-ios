//
//  OpenIdServiceTests.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 3/6/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest
@testable import ZenKeySDK

class OpenIdServiceTests: XCTestCase {
    var mockURLResolver = MockURLResolver()
    lazy var openIdService: OpenIdService = {
        OpenIdService(urlResolver: mockURLResolver)
    }()

    override func setUp() {
        super.setUp()
        mockURLResolver.clear()
    }

    func testInitialState() {
        XCTAssertFalse(openIdService.authorizationInProgress)
    }

    func testPassesParametersToURLResolver() {
        let testViewContorller = MockWindowViewController()
        let completion: OpenIdServiceCompletion = { _ in }
        openIdService.authorize(
            fromViewController: testViewContorller,
            carrierConfig: OpenIdServiceTests.mockCarrierConfig,
            authorizationParameters: OpenIdServiceTests.mockParameters,
            completion: completion
        )

        let passedViewController = try? UnwrapAndAssertNotNil(mockURLResolver.lastViewController)
        XCTAssertEqual(passedViewController, testViewContorller)

        guard case .inProgress(let request, _, _) = openIdService.state else {
            XCTFail("expected in progress state")
            return
        }

        let passedRequest = try? UnwrapAndAssertNotNil(mockURLResolver.lastRequest)
        XCTAssertEqual(passedRequest, request)
    }

    func testAuthorizationInProgress() {
        openIdService.authorize(
            fromViewController: MockWindowViewController(),
            carrierConfig: OpenIdServiceTests.mockCarrierConfig,
            authorizationParameters: OpenIdServiceTests.mockParameters,
            completion: { _ in })
        XCTAssertTrue(openIdService.authorizationInProgress)
    }

    func testCancelOperation() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: MockWindowViewController(),
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
            fromViewController: MockWindowViewController(),
            carrierConfig: OpenIdServiceTests.mockCarrierConfig,
            authorizationParameters: OpenIdServiceTests.mockParameters) { result in
                defer { expectation.fulfill() }
                guard case .code(let response) = result else {
                    XCTFail("expected to be successful")
                    return
                }

                XCTAssertEqual(response.code, "TESTCODE")
                XCTAssertEqual(response.mcc, MockSIMs.tmobile.mcc)
                XCTAssertEqual(response.mnc, MockSIMs.tmobile.mnc)
                XCTAssertEqual(response.redirectURI, OpenIdServiceTests.mockParameters.redirectURL)
        }

        let urlString = "testapp://zenkey/authorize?code=TESTCODE&state=bar"
        let handled = openIdService.resolve(url: URL(string: urlString)!)
        XCTAssertTrue(handled)
        wait(for: [expectation], timeout: timeout)
    }

    func testConcludeWithURLNoRequestInProgressError() {
        let urlString = "testapp://zenkey/authorize?code=TESTCODE&state=bar"
        let handled = openIdService.resolve(url: URL(string: urlString)!)
        XCTAssertFalse(handled)
    }

    func testConcludeWithURLStateMismatchError() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: MockWindowViewController(),
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

        let urlString = "testapp://zenkey/authorize?code=TESTCODE&state=BIZ"
        let handled = openIdService.resolve(url: URL(string: urlString)!)
        XCTAssertTrue(handled)
        wait(for: [expectation], timeout: timeout)
    }

    func testConcludeWithURLMissingAuthCodeError() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: MockWindowViewController(),
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

        let urlString = "testapp://zenkey/authorize?state=bar"
        let handled = openIdService.resolve(url: URL(string: urlString)!)
        XCTAssertTrue(handled)
        wait(for: [expectation], timeout: timeout)
    }

    // MARK: - URL passed errors

    func testParseURLErrorIdentifierOnly() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: MockWindowViewController(),
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

        let urlString = "testapp://zenkey/authorize?state=bar&error=\(OAuthErrorCode.invalidRequest.rawValue)"
        let handled = openIdService.resolve(url: URL(string: urlString)!)
        XCTAssertTrue(handled)
        wait(for: [expectation], timeout: timeout)
    }

    func testParseURLErrorIdentifierAndDescription() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: MockWindowViewController(),
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
        let urlString = "testapp://zenkey/authorize?state=bar&error=\(OAuthErrorCode.invalidRequest.rawValue)&error_description=foo"
        let handled = openIdService.resolve(url: URL(string: urlString)!)
        XCTAssertTrue(handled)
        wait(for: [expectation], timeout: timeout)
    }

    // MARK: - Redundant Requests

    func testDuplicateRequestsCancelsFirst() {
        let expectation = XCTestExpectation(description: "wait")
        openIdService.authorize(
            fromViewController: MockWindowViewController(),
            carrierConfig: OpenIdServiceTests.mockCarrierConfig,
            authorizationParameters: OpenIdServiceTests.mockParameters) { result in
                defer { expectation.fulfill() }
                guard case .cancelled = result else {
                    XCTFail("expected a cancelled result")
                    return
                }
        }
        openIdService.authorize(
            fromViewController: MockWindowViewController(),
            carrierConfig: OpenIdServiceTests.mockCarrierConfig,
            authorizationParameters: OpenIdServiceTests.mockParameters) { _ in }

        wait(for: [expectation], timeout: timeout)
    }
}

extension OpenIdServiceTests {
    static let mockParameters = OpenIdAuthorizationRequest.Parameters(
        clientId: "foo",
        redirectURL: URL(string: "testapp://zenkey/authorize")!,
        formattedScopes: "openid",
        state: "bar",
        nonce: nil,
        acrValues: [.aal1],
        prompt: nil,
        correlationId: nil,
        context: nil,
        loginHintToken: nil
    )

    static let mockRequest = OpenIdAuthorizationRequest(resource: URL.mocked, parameters: mockParameters)

    static let mockCarrierConfig = CarrierConfig(
        simInfo: MockSIMs.tmobile,
        openIdConfig: OpenIdConfig(
            authorizationEndpoint: URL.mocked,
            issuer: URL.mocked
        )
    )
}

// MARK: - Request Building

class AuthorizationURLBuilderTests: XCTestCase {

    func testBuildsCorrectRequestFromConfig() {
        let parameters = OpenIdAuthorizationRequest.Parameters(
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

        let request = OpenIdAuthorizationRequest(resource: URL.mocked, parameters: parameters)

        let expectedURL = URL(
            // swiftlint:disable:next line_length
            string: "https://rightpoint.com?client_id=1234&scope=openid%20profile%20email&redirect_uri=https://rightpoint.com&response_type=code"
        )!

        XCTAssertEqual(request.authorizationRequestURL, expectedURL)
    }

    func testBase64EncodesContextCorrectly() {
        let parameters = OpenIdAuthorizationRequest.Parameters(
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

        XCTAssertEqual(parameters.base64EncodedContext, "YnV6eg==")
    }

    func testBuildsCorrectRequestWithOptionalParameters() {
        let parameters = OpenIdAuthorizationRequest.Parameters(
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

        let request = OpenIdAuthorizationRequest(resource: URL.mocked, parameters: parameters)

        let expectedURL = URL(
            // swiftlint:disable:next line_length
            string: "https://rightpoint.com?client_id=1234&scope=openid%20profile%20email&redirect_uri=https://rightpoint.com&response_type=code&state=foo&nonce=bar&login_hint_token=boo&acr_values=aal1&correlation_id=fizz&context=YnV6eg%3D%3D&prompt=consent"
         )!
        XCTAssertEqual(request.authorizationRequestURL, expectedURL)
    }
}

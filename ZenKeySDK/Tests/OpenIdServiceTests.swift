//
//  OpenIdServiceTests.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 3/6/19.
//  Copyright © 2019 ZenKey, LLC. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
                XCTAssertEqual(response.mccmnc, MockSIMs.tmobile.mccmnc)
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
        loginHintToken: nil,
        theme: nil
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

class AuthorizationRequestPKCETests: XCTestCase {

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
        loginHintToken: nil,
        theme: nil
    )

    override class func setUp() {
        super.setUp()
    }

    func testGeneratesValidCodeVerifier() {
        let mockRequest = OpenIdAuthorizationRequest(resource: URL.mocked, parameters: Self.mockParameters)
        let codeVerifier = mockRequest.pkce.codeVerifier
        XCTAssertTrue(codeVerifier.count == 128)
        let validCharSet =
            CharacterSet.init(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        XCTAssertTrue(validCharSet.isSuperset(of: CharacterSet(charactersIn: codeVerifier)))
    }

    func testGeneratesValidCodeChallenge() {
        // Test PKCE spec value: https://tools.ietf.org/html/rfc7636#appendix-B
        let codeVerifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        let expectedCodeChallenge = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
        let testCodeChallenge = ProofKeyForCodeExchange.generateCodeChallenge(codeVerifier: codeVerifier)

        XCTAssertEqual(testCodeChallenge, expectedCodeChallenge)

        // Test full ZenKey verifier.
        let codeVerifier1 = "x9Y~JzZVf7I0WLA.pcX11iSIR8W8B8J~7s9xfA6ftqlW5MMaJHdz0QwyOFLzcTKdchX7HNVwE9ty6m6j5ofep02_-fcx.cwt4FKaqzrtPZEMPa2gj.R70fQ2RA4z82XM"
        let expectedCodeChallenge1 = "IjEemByjpngW8wqvWtBeylz6DTKmWvuNkyf6qK0e_Xo"
        let testCodeChallenge1 = ProofKeyForCodeExchange.generateCodeChallenge(codeVerifier: codeVerifier1)

        XCTAssertEqual(testCodeChallenge1, expectedCodeChallenge1)
    }
}

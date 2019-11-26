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
        loginHintToken: nil
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
        let codeVerifier = "JEg9Gg634BoVVTApb_XrVuS2vjHLnxO8MLRkdoLK_4K3Ypogd7ina144-KBXMQEZMLAGUeCxJWEXbDv9--_UXo1zklTWOZ37aB0D1HFsUYxsD7KIHoL-1CPCh3ELCMfV"

        let expectedCodeChallenge = "MTI4N2U2NjExYjBhMjQwNjAzMDM2ZGZkYmFlMDhhNzU4NzVjYWFiZDkxNmVhODNmYzJhOTg0YmQ4MWE3ODllMA=="
        let testCodeChallenge = ProofKeyForCodeExchange.generateCodeChallenge(codeVerifier: codeVerifier)

        XCTAssertEqual(testCodeChallenge, expectedCodeChallenge)

        let codeVerifier1 = "0zPYEcprd3VCoPo.CDmEqp5s47jfOpavpxZtmJ2gn_8g_rIIhdb4t8ItSnDJhDroZCBngc5bIDmVNQ~M065iGbn26Wg5JZhJ37Cy0gr9M2BNRslDiIu9OuG1IV_oMHxE"

        let expectedCodeChallenge1 = "MjMyNWMyMjgyYzE3OGU0NzUwZmY4YzFjMzFlODc0NzZkYWNjOGRhOTFjOWYzZWYxOGJiYzVmNGNjMjAxODVmOQ=="
        let testCodeChallenge1 = ProofKeyForCodeExchange.generateCodeChallenge(codeVerifier: codeVerifier1)

        XCTAssertEqual(testCodeChallenge1, expectedCodeChallenge1)
    }
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
        let challenge = request.pkce.codeChallenge.replacingOccurrences(of: "=", with: "%3D")

        let expectedURL = URL(
            // swiftlint:disable:next line_length
            string: "https://myzenkey.com?client_id=1234&scope=openid%20profile%20email&redirect_uri=https://myzenkey.com&response_type=code&code_challenge=\(challenge)&code_challenge_method=S256&sdk_version=\(VERSION)"
        )!

        XCTAssertEqual(request.authorizationRequestURL, expectedURL)
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
            context: "buz zz ",
            loginHintToken: "boo"
        )

        let parameters1 = OpenIdAuthorizationRequest.Parameters(
            clientId: "1234",
            redirectURL: URL.mocked,
            formattedScopes: "openid profile email",
            state: "foo",
            nonce: "bar",
            acrValues: [.aal1],
            prompt: .consent,
            correlationId: "fizz",
            context: "!*'();:@&=+$,/?#[]😀",
            loginHintToken: "boo"
        )

        let parameters2 = OpenIdAuthorizationRequest.Parameters(
            clientId: "1234",
            redirectURL: URL.mocked,
            formattedScopes: "openid profile email",
            state: "foo",
            nonce: "bar",
            acrValues: [.aal1],
            prompt: .consent,
            correlationId: "fizz",
            context: "ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz0123456789-_.~",
            loginHintToken: "boo"
        )

        let request = OpenIdAuthorizationRequest(resource: URL.mocked, parameters: parameters)
        let request1 = OpenIdAuthorizationRequest(resource: URL.mocked, parameters: parameters1)
        let request2 = OpenIdAuthorizationRequest(resource: URL.mocked, parameters: parameters2)

        let challenge = request.pkce.codeChallenge.replacingOccurrences(of: "=", with: "%3D")
        let challenge1 = request1.pkce.codeChallenge.replacingOccurrences(of: "=", with: "%3D")
        let challenge2 = request2.pkce.codeChallenge.replacingOccurrences(of: "=", with: "%3D")

        let expectedURL = URL(
            // swiftlint:disable:next line_length
            string: "https://myzenkey.com?client_id=1234&scope=openid%20profile%20email&redirect_uri=https://myzenkey.com&response_type=code&state=foo&nonce=bar&login_hint_token=boo&acr_values=a1&correlation_id=fizz&context=buz%20zz%20&prompt=consent&code_challenge=\(challenge)&code_challenge_method=S256&sdk_version=\(VERSION)"
         )!
        XCTAssertEqual(request.authorizationRequestURL, expectedURL)

        let expectedURL1 = URL(
            // swiftlint:disable:next line_length
            string: "https://myzenkey.com?client_id=1234&scope=openid%20profile%20email&redirect_uri=https://myzenkey.com&response_type=code&state=foo&nonce=bar&login_hint_token=boo&acr_values=a1&correlation_id=fizz&context=!*'();:@%26%3D+$,/?%23%5B%5D%F0%9F%98%80&prompt=consent&code_challenge=\(challenge1)&code_challenge_method=S256&sdk_version=\(VERSION)"
            )!
        XCTAssertEqual(request1.authorizationRequestURL, expectedURL1)

        let expectedURL2 = URL(
            // swiftlint:disable:next line_length
            string: "https://myzenkey.com?client_id=1234&scope=openid%20profile%20email&redirect_uri=https://myzenkey.com&response_type=code&state=foo&nonce=bar&login_hint_token=boo&acr_values=a1&correlation_id=fizz&context=ABCDEFGHIJKLMNOPQRSTUVWXYZ%20abcdefghijklmnopqrstuvwxyz0123456789-_.~&prompt=consent&code_challenge=\(challenge2)&code_challenge_method=S256&sdk_version=\(VERSION)"
            )!
        XCTAssertEqual(request2.authorizationRequestURL, expectedURL2)

        }
}

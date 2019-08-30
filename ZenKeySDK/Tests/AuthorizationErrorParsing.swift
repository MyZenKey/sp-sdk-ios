//
//  AuthorizationErrorParsing.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 5/9/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest
import Foundation
@testable import ZenKeySDK

class AuthorizationErrorParsing: XCTestCase {

    func testParseURLResponseStateMismatchError() {
        let error = URLResponseError.stateMismatch
        let authError = error.asAuthorizationError
        XCTAssertEqual(authError.code, SDKErrorCode.stateMismatch.rawValue)
        XCTAssertEqual(authError.description, "the state returned did not match the state sent")
        XCTAssertEqual(authError.errorType, AuthorizationError.ErrorType.unknownError)
    }

    func testParseMissingParameterError() {
        let error = URLResponseError.missingParameter("foo")
        let authError = error.asAuthorizationError
        XCTAssertEqual(authError.code, SDKErrorCode.missingParameter.rawValue)
        XCTAssertEqual(authError.description, "the paramter 'foo' is required")
        XCTAssertEqual(authError.errorType, AuthorizationError.ErrorType.unknownError)
    }

    func testParseErrorResponseError() {
        let code = "error_code"
        let desc = "error description"
        let error = URLResponseError.errorResponse(code, desc)
        let authError = error.asAuthorizationError
        XCTAssertEqual(authError.code, code)
        XCTAssertEqual(authError.description, desc)
        XCTAssertEqual(authError.errorType, AuthorizationError.ErrorType.unknownError)
    }

    func testParseErrorResponseMapsToKnownErrorTypes() {
        let code = OAuthErrorCode.invalidRequest.rawValue
        let errorType = OAuthErrorCode.invalidRequest.errorType
        let desc = "error description"
        let error = URLResponseError.errorResponse(code, desc)
        let authError = error.asAuthorizationError
        XCTAssertEqual(authError.code, code)
        XCTAssertEqual(authError.description, desc)
        XCTAssertEqual(authError.errorType, errorType)
    }

    func testParseDiscoveryIssuerError() {
        let code = "error_code"
        let desc = "error description"
        let mockError = IssuerResponse.Error(error: code, errorDescription: desc)
        let error = DiscoveryServiceError.issuerError(mockError)
        let authError = error.asAuthorizationError
        XCTAssertEqual(authError.code, code)
        XCTAssertEqual(authError.description, desc)
        XCTAssertEqual(authError.errorType, AuthorizationError.ErrorType.unknownError)
    }

    func testParseDiscoveryNetworkError() {
        let error = DiscoveryServiceError.networkError(.networkError(NSError.mocked))
        let authError = error.asAuthorizationError
        XCTAssertEqual(authError.code, SDKErrorCode.networkError.rawValue)
        XCTAssertEqual(authError.description, "a network error occurred")
        XCTAssertEqual(authError.errorType, AuthorizationError.ErrorType.networkFailure)
    }

    func testParseOpenIdURLResolverError() {
        let error = OpenIdServiceError.urlResolverError(NSError.mocked)
        let authError = error.asAuthorizationError
        XCTAssertEqual(authError.code, SDKErrorCode.networkError.rawValue)
        XCTAssertEqual(authError.description, "a network error occurred")
        XCTAssertEqual(authError.errorType, AuthorizationError.ErrorType.networkFailure)
    }

    func testParseOpenIdURLResponseErrorIsSameAsURLResponseError() {
        let error = OpenIdServiceError.urlResponseError(.stateMismatch)
        let authError = error.asAuthorizationError
        XCTAssertEqual(authError, URLResponseError.stateMismatch.asAuthorizationError)
    }

    func testParseMobileNetworkSelectionInvalidIdentifiersError() {
        let error = MobileNetworkSelectionError.invalidMCCMNC
        let authError = error.asAuthorizationError
        XCTAssertEqual(authError.code, SDKErrorCode.invalidParameter.rawValue)
        XCTAssertEqual(authError.description, "mccmnc paramter is misformatted")
        XCTAssertEqual(authError.errorType, AuthorizationError.ErrorType.unknownError)
    }

    func testParseMobileNetworkSelectionErrorIsSameAsURLResponseError() {
        let error = MobileNetworkSelectionError.urlResponseError(.stateMismatch)
        let authError = error.asAuthorizationError
        XCTAssertEqual(authError, URLResponseError.stateMismatch.asAuthorizationError)
    }
}

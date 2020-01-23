//
//  AuthorizationServiceTests+DiscoveryServiceInterface.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 6/12/19.
//  Copyright © 2019 ZenKey, LLC. All rights reserved.
//

import XCTest
@testable import ZenKeySDK

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

    func testDiscoveryServiceIsInvokedEvenIfNoSIMPresent() {
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
                XCTAssertEqual(payload.codeVerifier, mockedResponse.codeVerifier)
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

    func testMultipleRedirectsToDiscoveryUIReturnsAnError() {
        mockCarrierInfo.primarySIM = MockSIMs.unknown

        // if discovery always returns redirects we'll always return to discovery ui:
        mockDiscoveryService.responseQueue.mockResponses = [
            .unknownMobileNetwork(MockDiscoveryService.mockRedirect),
        ]

        // ensure it returns an error
        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.authorize(fromViewController: UIViewController()) { result in
            guard case .error(let error) = result else {
                XCTFail("expected an error response")
                return
            }
            XCTAssertEqual(error.code, SDKErrorCode.tooManyUIRedirects.rawValue)
            XCTAssertEqual(self.mockDiscoveryService.discoveryCallCount, 2)
            XCTAssertEqual(self.mockNetworkSelectionService.requestNetworkSelectionCallCount, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }
}

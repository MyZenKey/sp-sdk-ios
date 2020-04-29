//
//  AuthorizationServiceTests+DiscoveryServiceInterface.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 6/12/19.
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
                XCTAssertEqual(payload.mccmnc, mockedResponse.mccmnc)
                XCTAssertEqual(payload.codeVerifier, mockedResponse.codeVerifier)
                XCTAssertEqual(payload.nonce, mockedResponse.nonce)
                XCTAssertEqual(payload.acrValues, mockedResponse.acrValues)
                XCTAssertEqual(payload.correlationId, mockedResponse.correlationId)
                XCTAssertEqual(payload.context, mockedResponse.context)
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

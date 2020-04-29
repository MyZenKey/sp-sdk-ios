//
//  AuthorizationServiceTests+UserNotFoundError.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 6/6/19.
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

// MARK: - Mobile Network Selection Flow

extension AuthorizationServiceTests {

    // MARK: Inputs

    func testSIMPresentBypassesNetworkSelectionFlow() {
        mockCarrierInfo.primarySIM = MockSIMs.tmobile
        let expectation = XCTestExpectation(description: "async authorization")
        let expectedViewController = UIViewController()
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: expectedViewController) { _ in
                XCTAssertNil(self.mockNetworkSelectionService.lastViewController)
                XCTAssertNil(self.mockNetworkSelectionService.lastCompletion)
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testUnknownCarrierPassesOffToNetworkSelectionFlow() {
        mockNetworkSelectionFlow()
        let expectation = XCTestExpectation(description: "async authorization")
        let expectedViewController = UIViewController()
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: expectedViewController) { _ in
                XCTAssertEqual(
                    self.mockNetworkSelectionService.lastViewController, expectedViewController
                )
                expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    // MARK: Outputs

    func testNetworkSelectionFlowSuccess() {
        mockNetworkSelectionFlow()
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

    func testNetworkSelectionFlowError() {
        mockNetworkSelectionFlow()
        let expectedError: MobileNetworkSelectionError = .invalidMCCMNC
        mockNetworkSelectionService.mockResponse = .error(expectedError)
        let expectation = XCTestExpectation(description: "async authorization")
        let expectedViewController = UIViewController()
        authorizationService.authorize(
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

    func testNetworkSelectionFlowCancel() {
        mockNetworkSelectionFlow()
        mockNetworkSelectionService.mockResponse = .cancelled
        let expectation = XCTestExpectation(description: "async authorization")
        let expectedViewController = UIViewController()
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: expectedViewController) { result in
                defer { expectation.fulfill() }
                guard case .cancelled = result else {
                    XCTFail("expected an cancelled response")
                    return
                }
        }
        wait(for: [expectation], timeout: timeout)
    }
}

// MARK: - Helpers

private extension AuthorizationServiceTests {
    func mockNetworkSelectionFlow() {
        mockCarrierInfo.primarySIM = nil
        mockDiscoveryService.responseQueue.mockResponses = [
            .unknownMobileNetwork(MockDiscoveryService.mockRedirect),
            .knownMobileNetwork(MockDiscoveryService.mockSuccess),
        ]
    }
}

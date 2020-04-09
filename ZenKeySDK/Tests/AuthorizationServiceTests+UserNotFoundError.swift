//
//  AuthorizationServiceTests+UserNotFoundError.swift
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

// MARK: - Recovery flow
extension AuthorizationServiceTests {
    func testUserNotFoundSendPerformsDiscoveryFlowWithPromptTrue() {
        mockCarrierInfo.primarySIM = nil
        mockDiscoveryService.responseQueue.mockResponses = [
            .knownMobileNetwork(MockDiscoveryService.mockSuccess),
            .unknownMobileNetwork(MockDiscoveryService.mockRedirect),
            .knownMobileNetwork(MockDiscoveryService.mockSuccess),
        ]

        mockOpenIdService.responseQueue.mockResponses = [
            .error(
                .urlResponseError(.errorResponse(ZenKeyErrorCode.userNotFound.rawValue, nil))
            ),
            .code(MockOpenIdService.mockSuccess),
        ]

        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: UIViewController()) { result in
                defer { expectation.fulfill() }
                guard case .code = result else {
                    XCTFail("expected a successful outcome")
                    return
                }
                XCTAssertEqual(self.mockDiscoveryService.discoveryCallCount, 3)
                XCTAssertEqual(self.mockNetworkSelectionService.lastPromptFlag, true)
        }

        mockDiscoveryService.didCallDiscover = {
            // initial call and final call should not pass prompt for "true" discovery
            // second call passes prompt to force discovery ui
            switch self.mockDiscoveryService.discoveryCallCount {
            case 1, 3:
                XCTAssertEqual(self.mockDiscoveryService.lastPromptFlag, false)
            case 2:
                XCTAssertEqual(self.mockDiscoveryService.lastPromptFlag, true)
            default:
                XCTFail("unexpected number of discovery calls: \(self.mockDiscoveryService.discoveryCallCount)")
            }
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testUserNotFoundSendPerformsDiscoveryEvenIfUIShownPrevious() {
        mockCarrierInfo.primarySIM = nil
        mockDiscoveryService.responseQueue.mockResponses = [
            .unknownMobileNetwork(MockDiscoveryService.mockRedirect),
            .knownMobileNetwork(MockDiscoveryService.mockSuccess),
            .unknownMobileNetwork(MockDiscoveryService.mockRedirect),
            .knownMobileNetwork(MockDiscoveryService.mockSuccess),
        ]

        mockOpenIdService.responseQueue.mockResponses = [
            .error(
                .urlResponseError(.errorResponse(ZenKeyErrorCode.userNotFound.rawValue, nil))
            ),
            .code(MockOpenIdService.mockSuccess),
        ]

        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: UIViewController()) { result in
                defer { expectation.fulfill() }
                guard case .code = result else {
                    XCTFail("expected a successful outcome")
                    return
                }

                XCTAssertEqual(self.mockDiscoveryService.discoveryCallCount, 4)
                XCTAssertEqual(self.mockNetworkSelectionService.requestNetworkSelectionCallCount, 2)
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testMultipleUserNotFoundErrorsReturnsError() {
        mockCarrierInfo.primarySIM = nil
        mockOpenIdService.responseQueue.mockResponses = [
            .error(
                .urlResponseError(.errorResponse(ZenKeyErrorCode.userNotFound.rawValue, nil))
            ),
            .error(
                .urlResponseError(.errorResponse(ZenKeyErrorCode.userNotFound.rawValue, nil))
            ),
        ]

        let expectation = XCTestExpectation(description: "async authorization")
        authorizationService.authorize(
            scopes: self.scopes,
            fromViewController: UIViewController()) { result in
                defer { expectation.fulfill() }
                guard case .error(let error) = result else {
                    XCTFail("expectecd a successful outcome")
                    return
                }

                XCTAssertEqual(error.code, ZenKeyErrorCode.userNotFound.rawValue)
        }
        wait(for: [expectation], timeout: timeout)
    }
}

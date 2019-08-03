//
//  AuthorizationServiceTests+UserNotFoundError.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 6/12/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest
@testable import CarriersSharedAPI

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
                .urlResponseError(.errorResponse(ProjectVerifyErrorCode.userNotFound.rawValue, nil))
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
                .urlResponseError(.errorResponse(ProjectVerifyErrorCode.userNotFound.rawValue, nil))
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
                .urlResponseError(.errorResponse(ProjectVerifyErrorCode.userNotFound.rawValue, nil))
            ),
            .error(
                .urlResponseError(.errorResponse(ProjectVerifyErrorCode.userNotFound.rawValue, nil))
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

                XCTAssertEqual(error.code, ProjectVerifyErrorCode.userNotFound.rawValue)
        }
        wait(for: [expectation], timeout: timeout)
    }
}

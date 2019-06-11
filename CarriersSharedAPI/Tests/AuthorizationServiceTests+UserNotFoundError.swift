//
//  AuthorizationServiceTests+UserNotFoundError.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 6/6/19.
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

                XCTAssertEqual(self.mockDiscoveryService.lastPromptFlag, true)
                XCTAssertEqual(self.mockNetworkSelectionService.lastPromptFlag, true)

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

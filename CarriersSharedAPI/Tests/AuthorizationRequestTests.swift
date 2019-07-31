//
//  AuthorizationRequestTests.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 7/31/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest
@testable import CarriersSharedAPI

struct MockDeviceInfo: DeviceInfoProtocol {
    var isTablet: Bool

    static let mockTablet = MockDeviceInfo(isTablet: true)
}

class AuthorizationRequestTests: XCTestCase {

    var request = requestFactory()

    static func requestFactory(
        deviceInfoProvider: DeviceInfoProtocol = DeviceInfo(),
        completion: @escaping AuthorizationCompletion = { _ in }) -> AuthorizationRequest {
        return AuthorizationRequest(
            deviceInfoProvider: deviceInfoProvider,
            viewController: UIViewController(),
            authorizationParameters: OpenIdAuthorizationRequest.Parameters.mocked,
            completion: completion)
    }

    static func tabletRequestFactory(
        completion: @escaping AuthorizationCompletion = { _ in }) -> AuthorizationRequest {
        return requestFactory(deviceInfoProvider: MockDeviceInfo.mockTablet, completion: completion)
    }

    override func setUp() {
        super.setUp()
        request = AuthorizationRequestTests.requestFactory()
    }

    // MARK: - Initial State

    func testNonTabletInitialState() {
        guard case .undefined = request.state else {
            XCTFail("expected initial state to be undefined")
            return
        }
        XCTAssertFalse(request.isFinished)
        XCTAssertFalse(request.passPromptDiscovery)
        XCTAssertFalse(request.passPromptDiscoveryUI)
        XCTAssertFalse(request.isAttemptingMissingUserRecovery)
    }

    func testTabletInitialState() {
        request = AuthorizationRequestTests.tabletRequestFactory()
        guard case .undefined = request.state else {
            XCTFail("expected initial state to be undefined")
            return
        }
        XCTAssertTrue(request.passPromptDiscovery)
        XCTAssertFalse(request.isFinished)
        XCTAssertFalse(request.passPromptDiscoveryUI)
        XCTAssertFalse(request.isAttemptingMissingUserRecovery)
    }

    // MARK: - Discovery(UI) Prompts

    func testTableDoesntPromptAfterPerformingDiscovery() {
        request = AuthorizationRequestTests.tabletRequestFactory()

        passStateChangeThroughDiscovery(request: request)

        XCTAssertFalse(request.passPromptDiscovery)
        XCTAssertFalse(request.isFinished)
        XCTAssertFalse(request.passPromptDiscoveryUI)
        XCTAssertFalse(request.isAttemptingMissingUserRecovery)
    }

    func testPromptDiscoveryAndDiscoveryUIIfMissingUserRecovery() {
        passStateChangeThroughDiscovery(request: request)
        request.update(state: .missingUserRecovery)

        XCTAssertTrue(request.passPromptDiscovery)
        XCTAssertTrue(request.passPromptDiscoveryUI)
        XCTAssertTrue(request.isAttemptingMissingUserRecovery)

        XCTAssertFalse(request.isFinished)
    }

    func testDontPromptDiscoveryDuringMissingUserRecoveryAfterFirstPrompt() {
        passStateChangeThroughDiscovery(request: request)
        request.update(state: .missingUserRecovery)
        passStateChangeThroughDiscovery(request: request)

        XCTAssertFalse(request.passPromptDiscovery)
        XCTAssertTrue(request.passPromptDiscoveryUI)
        XCTAssertTrue(request.isAttemptingMissingUserRecovery)

        XCTAssertFalse(request.isFinished)
    }

    // MARK: - State Transitions

    func testFinishedStateTriggersCompletion() {
        let expectation = XCTestExpectation(description: "async")
        request = AuthorizationRequestTests.requestFactory() { result in
            defer { expectation.fulfill() }
            guard case .cancelled = result else {
                XCTFail("expected cancelled")
                return
            }
        }
        request.update(state: .concluding(.cancelled))
        request.update(state: .finished)
        wait(for: [expectation], timeout: timeout)
    }

    func testStateDoesntUpdateAfterFinished() {
        request.update(state: .concluding(.cancelled))
        request.update(state: .finished)
        request.update(state: .discovery(MockSIMs.tmobile))
        guard case .finished = request.state else {
            XCTFail("expected finished state")
            return
        }
    }

    func testErrorIfShowDiscoveryUITwice() {
        request.update(state: .mobileNetworkSelection(URL.mocked))
        request.update(state: .mobileNetworkSelection(URL.mocked))
        guard
            case .concluding(let result) = request.state,
            case .error(let error) = result else {
                XCTFail("expected error state")
            return
        }
        XCTAssertEqual(error, AuthorizationRequestError.tooManyRedirects.asAuthorizationError)
    }

    func testShowDiscoveryUITwiceIfEnteredMissingUserRecovery() {
        request.update(state: .mobileNetworkSelection(URL.mocked))
        request.update(state: .missingUserRecovery)
        request.update(state: .mobileNetworkSelection(URL.mocked))

        guard case .mobileNetworkSelection = request.state else {
            XCTFail("expected mobileNetworkSelection")
            return
        }
    }

    func testErrorIfEnterMissingUserRecoveryTwice() {
        request.update(state: .missingUserRecovery)
        request.update(state: .missingUserRecovery)
        guard
            case .concluding(let result) = request.state,
            case .error(let error) = result else {
                XCTFail("expected error state")
                return
        }
        XCTAssertEqual(error, AuthorizationRequestError.tooManyRecoveries.asAuthorizationError)
    }
}

private extension AuthorizationRequestTests {
    func passStateChangeThroughDiscovery(request: AuthorizationRequest) {
        request.update(state: .discovery(MockSIMs.tmobile))
        guard case .discovery = request.state else {
            XCTFail("expected update to discovery")
            return
        }
        request.update(state: .authorization(
            CarrierConfig(
                simInfo: MockSIMs.tmobile,
                openIdConfig: OpenIdConfig.mocked
            ))
        )
        guard case .authorization = request.state else {
            XCTFail("expected update to authorization")
            return
        }
    }
}

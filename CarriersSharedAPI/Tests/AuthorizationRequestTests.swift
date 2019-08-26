//
//  AuthorizationStateMachineTests.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 7/31/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest
@testable import CarriersSharedAPI

struct MockDeviceInfo: DeviceInfoProtocol {
    var isTablet: Bool

    static let mockNonTablet = MockDeviceInfo(isTablet: false)

    static let mockTablet = MockDeviceInfo(isTablet: true)
}

class AuthorizationStateMachineTests: XCTestCase {
    var stateMachine = stateMachineFactory()

    static func stateMachineFactory(
        deviceInfoProvider: DeviceInfoProtocol = MockDeviceInfo.mockNonTablet,
        onStateChange: @escaping AuthorizationServiceStateMachine.StateChangeHandler = { _ in }
        ) -> AuthorizationServiceStateMachine {
        return AuthorizationServiceStateMachine(
            deviceInfoProvider: deviceInfoProvider,
            onStateChange: onStateChange)
    }

    static func tabletStateMachineFactory(
        onStateChange: @escaping AuthorizationServiceStateMachine.StateChangeHandler = { _ in }
        ) -> AuthorizationServiceStateMachine {
        return stateMachineFactory(deviceInfoProvider: MockDeviceInfo.mockTablet, onStateChange: onStateChange)
    }

    override func setUp() {
        super.setUp()
        stateMachine = AuthorizationStateMachineTests.stateMachineFactory()
    }

    // MARK: - Initial State

    func testInitialState() {
        guard case .idle = stateMachine.state else {
            XCTFail("expected initial state to be undefined")
            return
        }
        XCTAssertFalse(stateMachine.isFinished)
        XCTAssertFalse(stateMachine.isAttemptingMissingUserRecovery)
    }

    // MARK: - Discovery(UI) Prompts

    func testNonTabletDoesntPassPromptToDiscoveryTheFirstTime() {
        let mockSIMInfo = MockSIMs.tmobile
        stateMachine.handle(event: .attemptDiscovery(mockSIMInfo))
        guard case .discovery(let simInfo, let passPrompt) = stateMachine.state else {
            XCTFail("expected update to discovery")
            return
        }

        XCTAssertEqual(simInfo, mockSIMInfo)
        XCTAssertFalse(passPrompt)
    }

    func testTabletPassesPromptToDiscoveryTheFirstTime() {
        stateMachine = AuthorizationStateMachineTests.tabletStateMachineFactory()
        let mockSIMInfo = MockSIMs.tmobile
        stateMachine.handle(event: .attemptDiscovery(mockSIMInfo))
        guard case .discovery(let simInfo, let passPrompt) = stateMachine.state else {
            XCTFail("expected update to discovery")
            return
        }

        XCTAssertEqual(simInfo, mockSIMInfo)
        XCTAssertTrue(passPrompt)
    }

    func testTabletDoesntPromptAfterPerformingDiscovery() {
        stateMachine = AuthorizationStateMachineTests.tabletStateMachineFactory()
        let mockSIMInfo = MockSIMs.tmobile
        stateMachine.handle(event: .attemptDiscovery(mockSIMInfo))
        stateMachine.handle(event: .attemptDiscovery(mockSIMInfo))

        guard case .discovery(let simInfo, let passPrompt) = stateMachine.state else {
            XCTFail("expected update to discovery")
            return
        }

        XCTAssertEqual(simInfo, mockSIMInfo)
        XCTAssertFalse(passPrompt)
    }

    func testPromptDiscoveryWithoutSIMInfoOneTimeAfterUserNotFoundError() {
        stateMachine.handle(event: .errored(AuthorizationStateMachineTests.userNotFoundError))
        guard case .discovery(let simInfoOne, let passPromptOne) = stateMachine.state else {
            XCTFail("expected update to discovery")
            return
        }
        XCTAssertNil(simInfoOne)
        XCTAssertTrue(passPromptOne)

        stateMachine.handle(event: .attemptDiscovery(nil))

        guard case .discovery(_, let passPromptTwo) = stateMachine.state else {
            XCTFail("expected update to discovery")
            return
        }
        XCTAssertFalse(passPromptTwo)
    }

    func testDiscoveryUIRecievesPromptValueAfterUserNotFoundError() {
        stateMachine.handle(event: .errored(AuthorizationStateMachineTests.userNotFoundError))
        stateMachine.handle(event: .redirected(URL.mocked))
        guard case .mobileNetworkSelection(_, let passPrompt) = stateMachine.state else {
            XCTFail("expected update to discovery")
            return
        }
        XCTAssertTrue(passPrompt)
    }

    // MARK: - State Transitions

    func testStateDoesntUpdateAfterFinished() {
        stateMachine.handle(event: .cancelled)
        stateMachine.handle(event: .attemptDiscovery(nil))
        XCTAssertTrue(stateMachine.isFinished)
    }

    func testErrorIfShowDiscoveryUITwice() {
        stateMachine.handle(event: .redirected(URL.mocked))
        stateMachine.handle(event: .redirected(URL.mocked))

        guard
            case .concluding(let result) = stateMachine.state,
            case .error(let error) = result else {
                XCTFail("expected error state")
            return
        }
        XCTAssertEqual(error, AuthorizationStateMachineError.tooManyRedirects.asAuthorizationError)
    }

    func testShowDiscoveryUITwiceIfEnteredMissingUserRecovery() {
        stateMachine.handle(event: .redirected(URL.mocked))
        stateMachine.handle(event: .errored(AuthorizationStateMachineTests.userNotFoundError))
        stateMachine.handle(event: .redirected(URL.mocked))

        guard case .mobileNetworkSelection = stateMachine.state else {
            XCTFail("expected mobileNetworkSelection")
            return
        }
    }

    // MARK: - Error

    func testCanRecoverFromMissingUserError() {
        stateMachine.handle(event:
            .errored(AuthorizationStateMachineTests.userNotFoundError)
        )
        XCTAssertFalse(stateMachine.isFinished)
    }

    func testOnlyRecoverFromRecoverableErrorOnce() {
        stateMachine.handle(event:
            .errored(AuthorizationStateMachineTests.userNotFoundError)
        )
        stateMachine.handle(event:
            .errored(AuthorizationStateMachineTests.userNotFoundError)
        )

        guard
            case .concluding(let result) = stateMachine.state,
            case .error(let error) = result else {
                XCTFail("expected error state")
                return
        }
        XCTAssertEqual(error, AuthorizationStateMachineError.tooManyRecoveries.asAuthorizationError)
    }

    func testUnrecoverableErrorConcludesWithError() {
        stateMachine.handle(event:
            .errored(OpenIdServiceError.viewControllerNotInHeirarchy.asAuthorizationError)
        )
        guard
            case .concluding(let result) = stateMachine.state,
            case .error = result else {
                XCTFail("expected error state")
                return
        }    }
}

private extension AuthorizationStateMachineTests {
    private static let userNotFoundError =
        URLResponseError.errorResponse(ProjectVerifyErrorCode.userNotFound.rawValue, nil)
            .asAuthorizationError
}

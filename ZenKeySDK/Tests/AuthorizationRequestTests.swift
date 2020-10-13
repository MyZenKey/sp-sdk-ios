//
//  AuthorizationStateMachineTests.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 7/31/19.
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
        URLResponseError.errorResponse(ZenKeyErrorCode.userNotFound.rawValue, nil)
            .asAuthorizationError
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
            loginHintToken: nil,
            theme: nil
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
            loginHintToken: "boo",
            theme: Theme.dark
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
            loginHintToken: "boo",
            theme: Theme.light
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
            loginHintToken: "boo",
            theme: Theme.dark
        )

        let request = OpenIdAuthorizationRequest(resource: URL.mocked, parameters: parameters)
        let request1 = OpenIdAuthorizationRequest(resource: URL.mocked, parameters: parameters1)
        let request2 = OpenIdAuthorizationRequest(resource: URL.mocked, parameters: parameters2)

        let challenge = request.pkce.codeChallenge.replacingOccurrences(of: "=", with: "%3D")
        let challenge1 = request1.pkce.codeChallenge.replacingOccurrences(of: "=", with: "%3D")
        let challenge2 = request2.pkce.codeChallenge.replacingOccurrences(of: "=", with: "%3D")

        let expectedURL = URL(
            // swiftlint:disable:next line_length
            string: "https://myzenkey.com?client_id=1234&scope=openid%20profile%20email&redirect_uri=https://myzenkey.com&response_type=code&state=foo&nonce=bar&login_hint_token=boo&acr_values=a1&correlation_id=fizz&context=buz%20zz%20&prompt=consent&code_challenge=\(challenge)&code_challenge_method=S256&sdk_version=\(VERSION)&options=dark"
         )!
        XCTAssertEqual(request.authorizationRequestURL, expectedURL)

        let expectedURL1 = URL(
            // swiftlint:disable:next line_length
            string: "https://myzenkey.com?client_id=1234&scope=openid%20profile%20email&redirect_uri=https://myzenkey.com&response_type=code&state=foo&nonce=bar&login_hint_token=boo&acr_values=a1&correlation_id=fizz&context=!*'();:@%26%3D+$,/?%23%5B%5D%F0%9F%98%80&prompt=consent&code_challenge=\(challenge1)&code_challenge_method=S256&sdk_version=\(VERSION)&options=light"
            )!
        XCTAssertEqual(request1.authorizationRequestURL, expectedURL1)

        let expectedURL2 = URL(
            // swiftlint:disable:next line_length
            string: "https://myzenkey.com?client_id=1234&scope=openid%20profile%20email&redirect_uri=https://myzenkey.com&response_type=code&state=foo&nonce=bar&login_hint_token=boo&acr_values=a1&correlation_id=fizz&context=ABCDEFGHIJKLMNOPQRSTUVWXYZ%20abcdefghijklmnopqrstuvwxyz0123456789-_.~&prompt=consent&code_challenge=\(challenge2)&code_challenge_method=S256&sdk_version=\(VERSION)&options=dark"
            )!
        XCTAssertEqual(request2.authorizationRequestURL, expectedURL2)

        }
}

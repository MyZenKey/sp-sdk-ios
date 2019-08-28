//
//  ZenKeyAuthorizeButtonTests.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 4/12/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest
@testable import ZenKeySDK

class MockCurrentControllerContextProvider: CurrentControllerContextProvider {
    var currentController: UIViewController?
}

class MockAuthorizationButtonDelegate: ZenKeyAuthorizeButtonDelegate {

    var onWillBegin: (() -> Void)?
    var onDidFinish: ((AuthorizationResult) -> Void)?

    func buttonWillBeginAuthorizing(_ button: ZenKeyAuthorizeButton) {
        onWillBegin?()
    }

    func buttonDidFinish(
        _ button: ZenKeyAuthorizeButton,
        withResult result: AuthorizationResult) {
        onDidFinish?(result)
    }
}

class MockBrandingProvider: BrandingProvider {
    var buttonBranding: Branding {
        return .default
    }

    var brandingDidChange: ((Branding) -> Void)?
}

class ZenKeyAuthorizeButtonTests: XCTestCase {

    let mockControllerProvider = MockCurrentControllerContextProvider()
    let mockAuthorizationService = MockAuthorizationService()
    let mockBrandingProvider = MockBrandingProvider()

    lazy var button = ZenKeyAuthorizeButton(
        authorizationService: mockAuthorizationService,
        controllerContextProvider: mockControllerProvider,
        brandingProvider: mockBrandingProvider
    )

    override func setUp() {
        super.setUp()
        mockControllerProvider.currentController = UIViewController()
        mockAuthorizationService.clear()

        button = ZenKeyAuthorizeButton(
            authorizationService: mockAuthorizationService,
            controllerContextProvider: mockControllerProvider,
            brandingProvider: mockBrandingProvider
        )
    }

    func testDefaultAppearance() {
        let appearance = ZenKeyBrandedButton.Appearance.dark
        XCTAssertTrue(button.isCurrentColorScheme(appearance.normal))
    }

    func testUpdateStyle() {
        button.style = .light
        let appearance = ZenKeyBrandedButton.Appearance.light
        XCTAssertTrue(button.isCurrentColorScheme(appearance.normal))
    }

    func testHighlightApperance() {
        button.isHighlighted = true
        let appearance = ZenKeyBrandedButton.Appearance.dark
        XCTAssertTrue(button.isCurrentColorScheme(appearance.highlighted))
    }

    func testHighlightDisabledAppearance() {
        button.isEnabled = false
        let appearance = ZenKeyBrandedButton.Appearance.dark
        XCTAssertTrue(button.isCurrentColorScheme(appearance.highlighted))
    }

    // TODO: handle branding
    // NOTE: will require mocking button via configCacheService:carrierInfoService:

    // MARK: - authorization:
    func testAuthorizationServiceCalled() {
        XCTAssertNil(mockAuthorizationService.lastCompletion)
        button.handlePress(sender: button)
        XCTAssertNotNil(mockAuthorizationService.lastCompletion)
    }

    func testRequestSetProperties() {
        let testScopes: [Scope] = [.secondFactor]
        let testAcrValues: [ACRValue]? = [.aal3, .aal2]
        let testRequestState: String? = "test-request-state"
        let testCorrelationId: String? = "test-correlation-id"
        let testContext: String? = "test-context"
        let testPrompt: PromptValue? = .consent
        let testNonce: String? = "test-nonce"

        button.scopes = testScopes
        button.acrValues = testAcrValues
        button.requestState = testRequestState
        button.correlationId = testCorrelationId
        button.context = testContext
        button.prompt = testPrompt
        button.nonce = testNonce

        button.handlePress(sender: button)
        XCTAssertEqual(mockAuthorizationService.lastScopes as? [Scope], testScopes)
        XCTAssertEqual(mockAuthorizationService.lastACRValues, testAcrValues)
        XCTAssertEqual(mockAuthorizationService.lastState, testRequestState)
        XCTAssertEqual(mockAuthorizationService.lastCorrelationId, testCorrelationId)
        XCTAssertEqual(mockAuthorizationService.lastContext, testContext)
        XCTAssertEqual(mockAuthorizationService.lastPrompt, testPrompt)
        XCTAssertEqual(mockAuthorizationService.lastNonce, testNonce)
    }

    func testGetsCurrentViewController() {
        button.handlePress(sender: button)
        XCTAssertEqual(
            mockAuthorizationService.lastViewController,
            mockControllerProvider.currentController
        )
    }

    func testDelegateWillStartCalled() {
        let mockDelegate = MockAuthorizationButtonDelegate()
        button.delegate = mockDelegate

        let expectation = XCTestExpectation(description: "wait")
        mockDelegate.onWillBegin = {
            expectation.fulfill()
        }
        button.handlePress(sender: button)
        wait(for: [expectation], timeout: timeout)
    }

    func testButtonCanMakeAnotherCallAfterCompletingTheFirst() {
        let mockDelegate = MockAuthorizationButtonDelegate()
        button.delegate = mockDelegate
        let expectation = XCTestExpectation(description: "wait")

        var willBeginCount = 0
        mockDelegate.onWillBegin = {
            willBeginCount += 1
        }

        mockDelegate.onDidFinish = { _ in
            self.button.handlePress(sender: self.button)
            XCTAssertEqual(willBeginCount, 2)
            expectation.fulfill()
        }

        button.handlePress(sender: button)
        wait(for: [expectation], timeout: timeout)
    }

    func testButtonUpdatesReportsResult() {
        let mockResponse = AuthorizedResponse(code: "foo", mcc: "bar", mnc: "bah", redirectURI: URL.mocked)
        mockAuthorizationService.mockResult = .code(mockResponse)
        let mockDelegate = MockAuthorizationButtonDelegate()
        button.delegate = mockDelegate

        let expectation = XCTestExpectation(description: "wait")
        mockDelegate.onDidFinish = { result in
            guard case .code(let response) = result else {
                XCTFail("expected a code resposne")
                return
            }
            XCTAssertEqual(response, mockResponse)
            expectation.fulfill()
        }
        button.handlePress(sender: button)
        wait(for: [expectation], timeout: timeout)
    }

    func testButtonIgnoresDuplicateRequests() {
        let firstCallContext = "foo"
        let secondCallContext = "bar"
        button.context = firstCallContext
        button.handlePress(sender: button)
        button.context = secondCallContext
        button.handlePress(sender: button)
        XCTAssertEqual(mockAuthorizationService.lastContext, firstCallContext)
    }

    func testButtonDisabledUponRequest() {
        button.handlePress(sender: button)
        XCTAssertFalse(button.isEnabled)
    }

    func testButtonEnabledUponCompletion() {
        let mockResponse = AuthorizedResponse(code: "foo", mcc: "bar", mnc: "bah", redirectURI: URL.mocked)
        mockAuthorizationService.mockResult = .code(mockResponse)
        let mockDelegate = MockAuthorizationButtonDelegate()
        button.delegate = mockDelegate
        let expectation = XCTestExpectation(description: "wait")
        mockDelegate.onDidFinish = { _ in
            XCTAssertTrue(self.button.isEnabled)
            expectation.fulfill()
        }

        button.handlePress(sender: button)
        wait(for: [expectation], timeout: timeout)
    }

    func testButtonCancelsOnAppDidBecomeActiveIfNoURL() {
        let mockDelegate = MockAuthorizationButtonDelegate()
        button.delegate = mockDelegate

        let expectation = XCTestExpectation(description: "wait")
        mockDelegate.onDidFinish = { _ in
            expectation.fulfill()
        }

        button.handlePress(sender: button)

        NotificationCenter.default.post(
            name: UIApplication.didBecomeActiveNotification,
            object: nil,
            userInfo: [:])

        wait(for: [expectation], timeout: timeout)
    }
}

private extension ZenKeyBrandedButton {
    func isCurrentColorScheme(_ colorScheme: Appearance.ColorScheme) -> Bool {
        guard
            let title = attributedTitle(for: state),
            let value = title.attribute(.foregroundColor, at: 0, effectiveRange: nil),
            let attributedTitleColor = value as? UIColor else {
                return false
        }

        return
            attributedTitleColor == colorScheme.title &&
            tintColor == colorScheme.image &&
            backgroundColor == colorScheme.background
    }
}

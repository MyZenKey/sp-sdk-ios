//
//  ProjectVerifyAuthorizeButtonTests.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 4/12/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest
@testable import CarriersSharedAPI

class MockCurrentControllerContextProvider: CurrentControllerContextProvider {
    var currentController: UIViewController?
}

class MockAuthorizationService: AuthorizationServiceProtocol {

    var mockResult: AuthorizationResult = .cancelled

    var lastScopes: [ScopeProtocol]?
    var lastACRValues: [ACRValue]?
    var lastState: String?
    var lastCorrelationId: String?
    var lastContext: String?
    var lastPrompt: PromptValue?
    var lastNonce: String?

    var lastViewController: UIViewController?
    var lastCompletion: AuthorizationCompletion?

    func clear() {
        mockResult = .cancelled

        lastScopes = nil
        lastACRValues = nil
        lastState = nil
        lastCorrelationId = nil
        lastContext = nil
        lastPrompt = nil
        lastNonce = nil

        lastViewController = nil
        lastCompletion = nil
    }

    var isAuthorizing: Bool = false

    // swiftlint:disable:next function_parameter_count
    func authorize(
        scopes: [ScopeProtocol],
        fromViewController viewController: UIViewController,
        acrValues: [ACRValue]?,
        state: String?,
        correlationId: String?,
        context: String?,
        prompt: PromptValue?,
        nonce: String?,
        completion: @escaping AuthorizationCompletion) {

        lastScopes = scopes
        lastACRValues = acrValues
        lastState = state
        lastCorrelationId = correlationId
        lastContext = context
        lastPrompt = prompt
        lastNonce = nonce

        lastViewController = viewController
        lastCompletion = completion

        isAuthorizing = true

        DispatchQueue.main.async {
            self.isAuthorizing = false
            completion(self.mockResult)
        }
    }

    func cancel() { }
}

class MockAuthorizationButtonDelegate: ProjectVerifyAuthorizeButtonDelegate {

    var onWillBegin: (() -> Void)?
    var onDidFinish: ((AuthorizationResult) -> Void)?

    func buttonWillBeginAuthorizing(_ button: ProjectVerifyAuthorizeButton) {
        onWillBegin?()
    }

    func buttonDidFinish(
        _ button: ProjectVerifyAuthorizeButton,
        withResult result: AuthorizationResult) {
        onDidFinish?(result)
    }
}

class MockBrandingProvider: BrandingProvider {
    var branding: Branding {
        return .default
    }
}

class ProjectVerifyAuthorizeButtonTests: XCTestCase {

    let mockControllerProvider = MockCurrentControllerContextProvider()
    let mockAuthorizationService = MockAuthorizationService()
    let mockBrandingProvider = MockBrandingProvider()

    lazy var button = ProjectVerifyAuthorizeButton(
        authorizationService: mockAuthorizationService,
        controllerContextProvider: mockControllerProvider,
        brandingProvider: mockBrandingProvider
    )

    override func setUp() {
        super.setUp()
        mockControllerProvider.currentController = UIViewController()
        mockAuthorizationService.clear()

        button = ProjectVerifyAuthorizeButton(
            authorizationService: mockAuthorizationService,
            controllerContextProvider: mockControllerProvider,
            brandingProvider: mockBrandingProvider
        )
    }

    func testDefaultAppearance() {
        let appearance = ProjectVerifyBrandedButton.Appearance.dark
        XCTAssertTrue(button.isCurrentColorScheme(appearance.normal))
    }

    func testUpdateStyle() {
        button.style = .light
        let appearance = ProjectVerifyBrandedButton.Appearance.light
        XCTAssertTrue(button.isCurrentColorScheme(appearance.normal))
    }

    func testHighlightApperance() {
        button.isHighlighted = true
        let appearance = ProjectVerifyBrandedButton.Appearance.dark
        XCTAssertTrue(button.isCurrentColorScheme(appearance.highlighted))
    }

    func testHighlightDisabledAppearance() {
        button.isEnabled = false
        let appearance = ProjectVerifyBrandedButton.Appearance.dark
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
        let mockResponse = AuthorizedResponse(code: "foo", mcc: "bar", mnc: "bah")
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
}

private extension ProjectVerifyBrandedButton {
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

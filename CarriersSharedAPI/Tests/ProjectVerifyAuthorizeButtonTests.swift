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
    var lastViewController: UIViewController?
    var lastCompletion: AuthorizationCompletion?
    
    func clear() {
        mockResult = .cancelled
        lastScopes = nil
        lastViewController = nil
        lastCompletion = nil
    }
    
    func connectWithProjectVerify(
        scopes: [ScopeProtocol],
        fromViewController viewController: UIViewController,
        completion: @escaping AuthorizationCompletion) {
     
        lastScopes = scopes
        lastViewController = viewController
        lastCompletion = completion
        
        DispatchQueue.main.async {
            completion(self.mockResult)
        }
    }
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

class ProjectVerifyAuthorizeButtonTests: XCTestCase {
    
    let mockControllerProvider = MockCurrentControllerContextProvider()
    let mockAuthorizationService = MockAuthorizationService()

    var button = ProjectVerifyAuthorizeButton()
    
    override func setUp() {
        super.setUp()
        mockControllerProvider.currentController = UIViewController()
        mockAuthorizationService.clear()
        
        button = ProjectVerifyAuthorizeButton(
            authorizationService: mockAuthorizationService,
            controllerContextProvider: mockControllerProvider
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
    
    func testRequestSetScopes() {
        let testScopes: [Scope] = [.secondFactor]
        button.scopes = testScopes
        button.handlePress(sender: button)
        XCTAssertEqual(mockAuthorizationService.lastScopes as? [Scope], testScopes)
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
    
    func testButtonCannotMakeRedundantAuthorizeCalls() {
        let mockDelegate = MockAuthorizationButtonDelegate()
        button.delegate = mockDelegate
        
        var willBeginCount = 0
        mockDelegate.onWillBegin = {
            willBeginCount += 1
        }

        button.handlePress(sender: button)
        button.handlePress(sender: button)
        XCTAssertEqual(willBeginCount, 1)
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

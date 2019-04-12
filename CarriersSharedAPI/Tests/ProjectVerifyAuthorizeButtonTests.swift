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
    
    func buttonWillBeginAuthorizing(_ button: ProjectVerifyAuthorizeButton) {
        
    }
    
    func buttonDidFinish(
        _ button: ProjectVerifyAuthorizeButton,
        withResult result: AuthorizationResult) {
        
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
    
    func testUpdateStyle() {
        
    }
    
    func testIsHighlightedAppearance() {
        
    }

    func testIsDisabledAppearance() {
        
    }

    func testAuthorizationServiceCalled() {
        
    }
}

private extension ProjectVerifyAuthorizeButtonTests {
    
}

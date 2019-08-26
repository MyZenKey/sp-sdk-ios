//
//  MockAuthorizationService.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 8/22/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
@testable import CarriersSharedAPI

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

        isAuthorizing = false
    }

    private(set) var isAuthorizing: Bool = false

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

    func cancel() {
        isAuthorizing = false
    }
}

//
//  MockAuthorizationService.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 8/22/19.
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

import Foundation
@testable import ZenKeySDK

class MockAuthorizationService: AuthorizationServiceProtocol {

    var mockResult: AuthorizationResult = .cancelled

    var lastScopes: [ScopeProtocol]?
    var lastACRValues: [ACRValue]?
    var lastState: String?
    var lastCorrelationId: String?
    var lastContext: String?
    var lastPrompt: PromptValue?
    var lastNonce: String?
    var lastTheme: Theme?

    var lastViewController: UIViewController?
    var lastCompletion: AuthorizationCompletion?

    private(set) var cancelCallCount: Int = 0

    func clear() {
        mockResult = .cancelled

        lastScopes = nil
        lastACRValues = nil
        lastState = nil
        lastCorrelationId = nil
        lastContext = nil
        lastPrompt = nil
        lastNonce = nil
        lastTheme = nil

        lastViewController = nil
        lastCompletion = nil

        cancelCallCount = 0

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
        theme: Theme?,
        completion: @escaping AuthorizationCompletion) {

        lastScopes = scopes
        lastACRValues = acrValues
        lastState = state
        lastCorrelationId = correlationId
        lastContext = context
        lastPrompt = prompt
        lastNonce = nonce
        lastTheme = theme

        lastViewController = viewController
        lastCompletion = completion

        isAuthorizing = true

        DispatchQueue.main.async {
            self.isAuthorizing = false
            completion(self.mockResult)
        }
    }

    func cancel() {
        cancelCallCount += 1
        isAuthorizing = false
        mockResult = .cancelled
    }
}

//
//  MockOpenIdService.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 5/30/19.
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

import UIKit
@testable import ZenKeySDK

class MockOpenIdService: OpenIdServiceProtocol {

    static let mockSuccess = AuthorizedResponse(code: "abc123",
                                                mccmnc: "123456",
                                                redirectURI: URL.mocked,
                                                codeVerifier: "JEg9Gg634BoVVTApb_XrVuS2vjHLnxO8MLRkdoLK_4K3Ypogd7ina144-KBXMQEZMLAGUeCxJWEXbDv9--_UXo1zklTWOZ37aB0D1HFsUYxsD7KIHoL-1CPCh3ELCMfV",
                                                nonce: "654321",
                                                acrValues: ZenKeySDK.ACRValue.aal3.rawValue,
                                                correlationId: "162534",
                                                context: "Transfer initiated successfully",
                                                clientId: "abc123")
    var lastParameters: OpenIdAuthorizationRequest.Parameters?
    var lastCompletion: OpenIdServiceCompletion?
    var lastViewController: UIViewController?

    var holdCompletionUntilURL: Bool = false
    var lastURL: URL?

    var didCallAuthorizeHook: (() -> Void)?

    private(set) var authorizeCallCount = 0

    var mockResponse: OpenIdServiceResult = .code(MockOpenIdService.mockSuccess) {
        didSet {
            responseQueue.mockResponses = [mockResponse]
        }
    }

    var responseQueue = MockResponseQueue<OpenIdServiceResult>([
        .code(MockOpenIdService.mockSuccess),
    ])

    func clear() {
        lastParameters = nil
        lastViewController = nil
        responseQueue.clear()
        authorizeCallCount = 0

        lastURL = nil
        holdCompletionUntilURL = false
        didCallAuthorizeHook = nil
    }

    func authorize(
        fromViewController viewController: UIViewController,
        carrierConfig: CarrierConfig,
        authorizationParameters: OpenIdAuthorizationRequest.Parameters,
        completion: @escaping OpenIdServiceCompletion) {

        authorizeCallCount += 1
        self.lastViewController = viewController
        self.lastParameters = authorizationParameters
        self.lastCompletion = completion

        if !holdCompletionUntilURL {
            DispatchQueue.main.async {
                self.complete()
            }
        }
        didCallAuthorizeHook?()
    }

    var authorizationInProgress: Bool = false

    func cancelCurrentAuthorizationSession() { }

    func resolve(url: URL) -> Bool {
        lastURL = url
        if lastCompletion != nil {
            complete()
            return true
        } else {
            return false
        }
    }

    func concludeAuthorizationFlow(result: AuthorizationResult) { }

    private func complete() {
        lastCompletion?(responseQueue.getResponse())
    }
}

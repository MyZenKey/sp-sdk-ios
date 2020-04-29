//
//  MockNetworkSelectionService.swift
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

class MockMobileNetworkSelectionService: MobileNetworkSelectionServiceProtocol {

    static let mockSuccess: MobileNetworkSelectionResponse = MobileNetworkSelectionResponse(
        simInfo: MockSIMs.tmobile,
        loginHintToken: nil
    )

    private(set) var requestNetworkSelectionCallCount = 0
    var mockResponse: MobileNetworkSelectionResult = .networkInfo(MockMobileNetworkSelectionService.mockSuccess)

    var lastResource: URL?
    var lastViewController: UIViewController?
    var lastPromptFlag: Bool?
    var lastCompletion: MobileNetworkSelectionCompletion?

    var holdCompletionUntilURL: Bool = false
    var lastURL: URL?

    var didCallRequestUserNetworkHook: (() -> Void)?

    func clear() {
        lastResource = nil
        lastViewController = nil
        lastPromptFlag = nil
        lastCompletion = nil
        requestNetworkSelectionCallCount = 0

        lastURL = nil
        holdCompletionUntilURL = false
        didCallRequestUserNetworkHook = nil
    }

    func requestUserNetworkSelection(
        fromResource resource: URL,
        fromCurrentViewController viewController: UIViewController,
        prompt: Bool = false,
        completion: @escaping MobileNetworkSelectionCompletion) {

        requestNetworkSelectionCallCount += 1
        self.lastResource = resource
        self.lastViewController = viewController
        self.lastPromptFlag = prompt
        self.lastCompletion = completion

        if !holdCompletionUntilURL {
            DispatchQueue.main.async {
                completion(self.mockResponse)
            }
        }
        didCallRequestUserNetworkHook?()
    }

    func resolve(url: URL) -> Bool {
        lastURL = url
        if lastCompletion != nil {
            complete()
            return true
        } else {
            return false
        }
    }

    private func complete() {
        lastCompletion?(mockResponse)
    }
}

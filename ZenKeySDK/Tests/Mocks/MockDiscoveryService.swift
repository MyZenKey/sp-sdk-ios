//
//  MockDiscoveryService.swift
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

import Foundation
import XCTest
@testable import ZenKeySDK

class MockDiscoveryService: DiscoveryServiceProtocol {
    static let mockSuccess = CarrierConfig(
        simInfo: MockSIMs.tmobile,
        openIdConfig: OpenIdConfig(
            authorizationEndpoint: URL.mocked,
            issuer: URL.mocked
        )
    )

    static let mockRedirect = IssuerResponse.Redirect(
        error: "foo", redirectURI: URL.mocked
    )

    private(set) var discoveryCallCount = 0
    var lastSIMInfo: SIMInfo?
    var lastPromptFlag: Bool?
    var lastCompletion: DiscoveryServiceCompletion?

    var didCallDiscover: (() -> Void)?

    /// FIFO responses
    var responseQueue = MockResponseQueue<DiscoveryServiceResult>([
        .knownMobileNetwork(MockDiscoveryService.mockSuccess),
    ])

    func clear() {
        lastSIMInfo = nil
        lastCompletion = nil
        lastPromptFlag = nil
        responseQueue.clear()
        discoveryCallCount = 0
        didCallDiscover = nil
    }

    func discoverConfig(
        forSIMInfo simInfo: SIMInfo?,
        prompt: Bool,
        completion: @escaping DiscoveryServiceCompletion) {
        discoveryCallCount += 1
        lastSIMInfo = simInfo
        lastCompletion = completion
        lastPromptFlag = prompt

        didCallDiscover?()

        DispatchQueue.main.async {
            completion(self.responseQueue.getResponse())
        }
    }
}

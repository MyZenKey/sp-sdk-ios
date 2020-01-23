//
//  MockDiscoveryService.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 5/30/19.
//  Copyright © 2019 ZenKey, LLC. All rights reserved.
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

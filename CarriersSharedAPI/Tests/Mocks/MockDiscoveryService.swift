//
//  MockDiscoveryService.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 5/30/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
import XCTest
@testable import CarriersSharedAPI

class MockDiscoveryService: DiscoveryServiceProtocol {
    static let mockSuccess = CarrierConfig(
        simInfo: MockSIMs.tmobile,
        openIdConfig: OpenIdConfig(
            tokenEndpoint: URL.mocked,
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
    }

    func discoverConfig(
        forSIMInfo simInfo: SIMInfo?,
        prompt: Bool,
        completion: @escaping DiscoveryServiceCompletion) {
        discoveryCallCount += 1
        lastSIMInfo = simInfo
        lastCompletion = completion
        lastPromptFlag = prompt

        DispatchQueue.main.async {
            completion(self.responseQueue.getResponse())
        }
    }
}

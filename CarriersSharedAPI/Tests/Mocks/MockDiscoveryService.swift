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
    }

    func discoverConfig(
        forSIMInfo simInfo: SIMInfo?,
        prompt: Bool,
        completion: @escaping DiscoveryServiceCompletion) {
        lastSIMInfo = simInfo
        lastCompletion = completion
        lastPromptFlag = prompt

        DispatchQueue.main.async {
            completion(self.responseQueue.getResponse())
        }
    }
}

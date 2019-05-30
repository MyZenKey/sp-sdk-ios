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
    var lastCompletion: DiscoveryServiceCompletion?

    /// FIFO responses
    var mockResponses: [DiscoveryServiceResult] = [
        .knownMobileNetwork(MockDiscoveryService.mockSuccess),
    ]

    func clear() {
        lastSIMInfo = nil
        lastCompletion = nil
        mockResponses = [
            .knownMobileNetwork(MockDiscoveryService.mockSuccess),
        ]
    }

    func discoverConfig(
        forSIMInfo simInfo: SIMInfo?,
        completion: @escaping DiscoveryServiceCompletion) {
        lastSIMInfo = simInfo
        lastCompletion = completion

        DispatchQueue.main.async {
            guard let result = self.mockResponses.first else {
                XCTFail("not enough reponses configured")
                return
            }
            self.mockResponses = Array(self.mockResponses.dropFirst())
            completion(result)
        }
    }
}

//
//  MockNetworkSelectionService.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 5/30/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
@testable import CarriersSharedAPI

class MockMobileNetworkSelectionService: MobileNetworkSelectionServiceProtocol {

    static let mockSuccess: MobileNetworkSelectionResponse = MobileNetworkSelectionResponse(
        simInfo: MockSIMs.tmobile,
        loginHintToken: nil
    )

    var mockResponse: MobileNetworkSelectionResult = .networkInfo(MockMobileNetworkSelectionService.mockSuccess)

    var lastResource: URL?
    var lastViewController: UIViewController?
    var lastCompletion: MobileNetworkSelectionCompletion?

    func clear() {
        lastResource = nil
        lastViewController = nil
        lastCompletion = nil
    }

    func requestUserNetworkSelection(
        fromResource resource: URL,
        fromCurrentViewController viewController: UIViewController,
        completion: @escaping MobileNetworkSelectionCompletion) {

        self.lastResource = resource
        self.lastViewController = viewController
        self.lastCompletion = completion

        DispatchQueue.main.async {
            completion(self.mockResponse)
        }
    }

    func resolve(url: URL) -> Bool { return true }
}

//
//  MockNetworkSelectionService.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 5/30/19.
//  Copyright © 2019 ZenKey, LLC. All rights reserved.
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

//
//  MockURLResolver.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 7/16/19.
//  Copyright © 2019 ZenKey, LLC. All rights reserved.
//

import UIKit
@testable import ZenKeySDK

class MockURLResolver: OpenIdURLResolverProtocol {
    var lastRequest: OpenIdAuthorizationRequest?
    var lastViewController: UIViewController?
    var lastParameters: OpenIdAuthorizationRequest.Parameters?
    var lastCompletion: OpenIdURLResolverDidCancel?

    func clear() {
        lastRequest = nil
        lastViewController = nil
        lastCompletion = nil
    }

    func resolve(
        request: OpenIdAuthorizationRequest,
        fromViewController viewController: UIViewController,
        onCancel: @escaping OpenIdURLResolverDidCancel) {
        lastRequest = request
        lastViewController = viewController
        lastCompletion = onCancel

    }

    func close(completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            completion()
        }
    }
}

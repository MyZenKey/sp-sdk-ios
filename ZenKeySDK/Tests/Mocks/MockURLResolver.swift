//
//  MockURLResolver.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 7/16/19.
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

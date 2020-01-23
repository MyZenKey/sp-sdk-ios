//
//  AuthorizationRequestContext.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 8/1/19.
//  Copyright © 2019 ZenKey, LLC.
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

class AuthorizationRequestContext {
    let viewController: UIViewController
    let completion: AuthorizationCompletion
    var parameters: OpenIdAuthorizationRequest.Parameters

    init(
        viewController: UIViewController,
        parameters: OpenIdAuthorizationRequest.Parameters,
        completion: @escaping AuthorizationCompletion) {
        self.viewController = viewController
        self.completion = completion
        self.parameters = parameters
    }

    func addState(_ state: String) {
        precondition(Thread.isMainThread)
        parameters.safeSet(state: state)
    }

    func addLoginHintToken(_ token: String?) {
        precondition(Thread.isMainThread)
        parameters.loginHintToken = token
    }
}

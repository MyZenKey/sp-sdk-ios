//
//  AuthorizationRequestContext.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 8/1/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
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

//
//  MockURLResolver.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 7/16/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import AppAuth
@testable import CarriersSharedAPI

class MockURLResolver: OpenIdURLResolverProtocol {

    var lastStorage: OpenIdExternalSessionStateStorage?
    var lastRequest: OIDAuthorizationRequest?
    var lastViewController: UIViewController?
    var lastParameters: OpenIdAuthorizationParameters?
    var lastCompletion: OpenIdURLResolverCompletion?

    func clear() {
        lastStorage = nil
        lastRequest = nil
        lastViewController = nil
        lastParameters = nil
        lastCompletion = nil
    }

    func resolve(
        request: OIDAuthorizationRequest,
        usingStorage storage: OpenIdExternalSessionStateStorage,
        fromViewController viewController: UIViewController,
        authorizationParameters: OpenIdAuthorizationParameters,
        completion: @escaping OpenIdURLResolverCompletion) {
        lastStorage = storage
        lastRequest = request
        lastViewController = viewController
        lastParameters = authorizationParameters
        lastCompletion = completion
    }

    func performCCIDAuthorization(
        request: OIDAuthorizationRequest,
        storage: OpenIdExternalSessionStateStorage,
        authorizationParameters: OpenIdAuthorizationParameters,
        completion: @escaping OpenIdURLResolverCompletion) {

    }
}

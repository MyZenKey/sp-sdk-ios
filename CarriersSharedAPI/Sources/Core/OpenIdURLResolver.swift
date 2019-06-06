//
//  OpenIdURLResolverProtocol.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 5/7/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
import AppAuth

typealias OpenIdURLResolverCompletion = (OIDAuthState?, Error?) -> Void

/// holds a reference to an in progress OIDExternalUserAgentSession in memory
/// a present session indicates the storage owns an inflights session.
protocol OpenIdExternalSessionStateStorage: class {
    var pendingSession: OIDExternalUserAgentSession? { get set }
}

protocol OpenIdURLResolverProtocol {
    func resolve(
        request: OIDAuthorizationRequest,
        usingStorage storage: OpenIdExternalSessionStateStorage,
        fromViewController viewController: UIViewController,
        authorizationParameters: OpenIdAuthorizationParameters,
        completion: @escaping OpenIdURLResolverCompletion
    )

    func performCCIDAuthorization(
        request: OIDAuthorizationRequest,
        storage: OpenIdExternalSessionStateStorage,
        authorizationParameters: OpenIdAuthorizationParameters,
        completion: @escaping OpenIdURLResolverCompletion
    )

    func performSafariAuthorization(
        request: OIDAuthorizationRequest,
        storage: OpenIdExternalSessionStateStorage,
        fromViewController viewController: UIViewController,
        completion: @escaping OpenIdURLResolverCompletion
    )
}

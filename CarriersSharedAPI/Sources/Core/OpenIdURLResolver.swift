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
        authorizationConfig: OpenIdAuthorizationConfig,
        completion: @escaping OpenIdURLResolverCompletion
    )

    func performCCIDAuthorization(
        request: OIDAuthorizationRequest,
        storage: OpenIdExternalSessionStateStorage,
        authorizationConfig: OpenIdAuthorizationConfig,
        completion: @escaping OpenIdURLResolverCompletion
    )

    func performSafariAuthorization(
        request: OIDAuthorizationRequest,
        storage: OpenIdExternalSessionStateStorage,
        simInfo: SIMInfo,
        fromViewController viewController: UIViewController,
        completion: @escaping OpenIdURLResolverCompletion
    )
}

extension OpenIdAuthorizationConfig {
    var consentURLString: String {
        // NOTE: copy+paste from sample code
        // I'm not certain that this is correct...
        // a) do we need this url tansformation? it seems to be for adding a custom scheme
        // when we probably want to use universal links
        // b) passing the authorization url to the app store link might make sense but I'm not sure

        //swiftlint:disable:next line_length
        return "\(authorizationEndpoint)?client_id=\(clientId.urlEncode())&response_type=code&redirect_uri=\(redirectURL.absoluteString.urlEncode())&scope=\(formattedScopes.urlEncode())&state=\(state.urlEncode())"
    }
}

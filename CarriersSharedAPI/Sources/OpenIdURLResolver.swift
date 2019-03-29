//
//  OpenIdURLResolver.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 3/6/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
import AppAuth

typealias OpenIdURLResolverCompletion = (OIDAuthState?, Error?) -> Void

protocol OpenIdURLResolverProtocol {
    func resolve(
        withRequest request: OIDAuthorizationRequest,
        fromViewController viewController: UIViewController,
        authorizationConfig: OpenIdAuthorizationConfig,
        completion: @escaping OpenIdURLResolverCompletion
    )

    func performCCIDAuthorization(
        request: OIDAuthorizationRequest,
        authorizationConfig: OpenIdAuthorizationConfig,
        completion: @escaping OpenIdURLResolverCompletion
    )

    func performSafariAuthorization(
        request: OIDAuthorizationRequest,
        simInfo: SIMInfo,
        fromViewController viewController: UIViewController,
        completion: @escaping OpenIdURLResolverCompletion
    )
}

extension OpenIdURLResolverProtocol {
    func performSafariAuthorization(
        request: OIDAuthorizationRequest,
        simInfo: SIMInfo,
        fromViewController viewController: UIViewController,
        completion: @escaping OpenIdURLResolverCompletion) {

        // since we don't rejoin via resumeExternalUserAgentFlowWithURL, we don't need to store the
        // sesssion
        OIDAuthState.authState(
            byPresenting: request,
            presenting: viewController,
            callback: { authState, error in
                guard
                    error == nil,
                    let authState = authState else {
                        completion(nil, error)
                        return
                }

                completion(authState, nil)
        })
    }
}

/// A url resolver which uses a hard coded xci url scheme
class XCISchemeOpenIdURLResolver: OpenIdURLResolverProtocol {
    func resolve(withRequest request: OIDAuthorizationRequest,
                 fromViewController viewController: UIViewController,
                 authorizationConfig: OpenIdAuthorizationConfig,
                 completion: @escaping OpenIdURLResolverCompletion) {

        if UIApplication.shared.canOpenURL(authorizationConfig.authorizationEndpoint) {
            self.performCCIDAuthorization(
                request: request,
                authorizationConfig: authorizationConfig,
                completion: completion
            )
        } else {
            self.performSafariAuthorization(
                request: request,
                simInfo: authorizationConfig.simInfo,
                fromViewController: viewController,
                completion: completion
            )
        }
    }

    func performCCIDAuthorization(
        request: OIDAuthorizationRequest,
        authorizationConfig: OpenIdAuthorizationConfig,
        completion: @escaping OpenIdURLResolverCompletion) {

        let consentURLString = authorizationConfig.consentURLString
        let externalUserAgent = OIDExternalUserAgentIOSCustomBrowser(
            urlTransformation: { request in return request },
            canOpenURLScheme: "xci",
            appStore: URL(string: consentURLString)
        )!

        // since we don't rejoin via resumeExternalUserAgentFlowWithURL, we don't need to store the
        // sesssion
        OIDAuthState.authState(
            byPresenting: request,
            externalUserAgent: externalUserAgent,
            callback: completion
        )
    }
}

private extension OpenIdAuthorizationConfig {
    var consentURLString: String {
        // NOTE: copy+paste from sample code
        // I'm not certain that this is correct...
        // a) do we need this url tansformation? it seems to be for adding a custom scheme
        // when we probably want to use universal links
        // b) passing the authorization url to the app store link might make sense but I'm not sure
        return "\(authorizationEndpoint)?client_id=\(clientId.urlEncode())&response_type=code&redirect_uri=\(redirectURL.absoluteString.urlEncode())&scope=\(formattedScopes.urlEncode())&state=\(state.urlEncode())"
    }
}

/// A url resolver which uses universal links
class OpenIdURLResolver: OpenIdURLResolverProtocol {
    func resolve(
        withRequest request: OIDAuthorizationRequest,
        fromViewController viewController: UIViewController,
        authorizationConfig: OpenIdAuthorizationConfig,
        completion: @escaping OpenIdURLResolverCompletion) {
        // NOTE: we need to use stage, not test, for universal links to work with att
        // ie:
        // URL(string: "https://oidc.stage.xlogin.att.com/mga/sps/oauth/oauth20/authorize")!,
        UIApplication.shared.open(
            authorizationConfig.authorizationEndpoint,
            options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: true]
        ) { success in
            if success {
                self.performCCIDAuthorization(
                    request: request,
                    authorizationConfig: authorizationConfig,
                    completion: completion
                )
            }
            else {
                self.performSafariAuthorization(
                    request: request,
                    simInfo: authorizationConfig.simInfo,
                    fromViewController: viewController,
                    completion: completion
                )
            }
        }
    }

    func performCCIDAuthorization(
        request: OIDAuthorizationRequest,
        authorizationConfig: OpenIdAuthorizationConfig,
        completion: @escaping OpenIdURLResolverCompletion) {

        // TODO: clean up /cancel existing session semantics:
        let consentURLString = authorizationConfig.consentURLString
        print("Checking if " + consentURLString + " is part of a universal link")
        let urlTransformation = OIDExternalUserAgentIOSCustomBrowser.urlTransformationSchemeConcatPrefix(consentURLString)

        let externalUserAgent = OIDExternalUserAgentIOSCustomBrowser(
            urlTransformation: urlTransformation,
            canOpenURLScheme: nil,
            appStore: URL(string: consentURLString)
        )!

        // since we don't rejoin via resumeExternalUserAgentFlowWithURL, we don't need to store the
        // sesssion
        OIDAuthState.authState(
            byPresenting: request,
            externalUserAgent: externalUserAgent,
            callback: completion
        )
    }
}

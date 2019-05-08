//
//  OpenIdURLResolver.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 3/6/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
import AppAuth

/// iOS only implementation using safari view controller
extension OpenIdURLResolverProtocol {
    func performSafariAuthorization(
        request: OIDAuthorizationRequest,
        storage: OpenIdExternalSessionStateStorage,
        simInfo: SIMInfo,
        fromViewController viewController: UIViewController,
        completion: @escaping OpenIdURLResolverCompletion) {

        // store the session as the presented vc can go out of scope
        let session = OIDAuthState.authState(
            byPresenting: request,
            presenting: viewController,
            callback: { authState, error in

                // This response will be a cancellation or potentially some sort of network error.
                // we will expect to recieive the redirect url through the handle url flow and
                // in all likelyhood clean this up manually.

                // TODO: verify errors here on cancel
                guard
                    error == nil,
                    let authState = authState else {
                        completion(nil, error)
                        return
                }

                completion(authState, nil)
        })

        storage.pendingSession = session
    }
}

/// A url resolver which uses universal links
struct OpenIdURLResolverIOS: OpenIdURLResolverProtocol {
    func resolve(
        request: OIDAuthorizationRequest,
        usingStorage storage: OpenIdExternalSessionStateStorage,
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
                    storage: storage,
                    authorizationConfig: authorizationConfig,
                    completion: completion
                )
            }
            else {
                self.performSafariAuthorization(
                    request: request,
                    storage: storage,
                    simInfo: authorizationConfig.simInfo,
                    fromViewController: viewController,
                    completion: completion
                )
            }
        }
    }

    func performCCIDAuthorization(
        request: OIDAuthorizationRequest,
        storage: OpenIdExternalSessionStateStorage,
        authorizationConfig: OpenIdAuthorizationConfig,
        completion: @escaping OpenIdURLResolverCompletion) {

        // TODO: clean up /cancel existing session semantics:
        let consentURLString = authorizationConfig.consentURLString
        let urlTransformation = OIDExternalUserAgentIOSCustomBrowser.urlTransformationSchemeConcatPrefix(consentURLString)

        let externalUserAgent = OIDExternalUserAgentIOSCustomBrowser(
            urlTransformation: urlTransformation,
            canOpenURLScheme: nil,
            appStore: URL(string: consentURLString)
        )!

        let session = OIDAuthState.authState(
            byPresenting: request,
            externalUserAgent: externalUserAgent,
            callback: completion
        )
        
        storage.pendingSession = session
    }
}

#if DEBUG

/// A url resolver which uses a hard coded xci url scheme
struct XCISchemeOpenIdURLResolverIOS: OpenIdURLResolverProtocol {
    func resolve(
        request: OIDAuthorizationRequest,
        usingStorage storage: OpenIdExternalSessionStateStorage,
        fromViewController viewController: UIViewController,
        authorizationConfig: OpenIdAuthorizationConfig,
        completion: @escaping OpenIdURLResolverCompletion) {

        if UIApplication.shared.canOpenURL(URL(string: "xci://")!) {

            // restructure resquest to user xci:// scheme for auth point
            // this reach backward pattern is not ideal and is for QA only!
            let openIdConfiguration = OIDServiceConfiguration(
                authorizationEndpoint: URL(string: "xci://authorize")!,
                tokenEndpoint: authorizationConfig.tokenEndpoint
            )

            let authorizationRequest: OIDAuthorizationRequest = OpenIdService
                .createAuthorizationRequest(
                    openIdServiceConfiguration: openIdConfiguration,
                    authorizationConfig: authorizationConfig
            )

            self.performCCIDAuthorization(
                request: authorizationRequest,
                storage: storage,
                authorizationConfig: authorizationConfig,
                completion: completion
            )
        } else {
            self.performSafariAuthorization(
                request: request,
                storage: storage,
                simInfo: authorizationConfig.simInfo,
                fromViewController: viewController,
                completion: completion
            )
        }
    }

    func performCCIDAuthorization(
        request: OIDAuthorizationRequest,
        storage: OpenIdExternalSessionStateStorage,
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
        let session = OIDAuthState.authState(
            byPresenting: request,
            externalUserAgent: externalUserAgent,
            callback: completion
        )

        storage.pendingSession = session
    }
}

#endif

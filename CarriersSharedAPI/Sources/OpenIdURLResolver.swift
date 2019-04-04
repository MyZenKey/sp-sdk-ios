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

/// holds a reference to an in progress OIDExternalUserAgentSession in memeory
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

///// A url resolver which uses a hard coded xci url scheme
class XCISchemeOpenIdURLResolver: OpenIdURLResolverProtocol {
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
struct OpenIdURLResolver: OpenIdURLResolverProtocol {
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
        print("Checking if " + consentURLString + " is part of a universal link")
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

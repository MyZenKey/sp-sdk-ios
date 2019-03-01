//
//  OpenIdService.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/27/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
import AppAuth

public struct AuthorizedResponse {
    public let code: String
    public let mcc: String
    public let mnc: String
}

public enum AuthorizationResult {
    case code(AuthorizedResponse)
    case error(Error)
}

public typealias AuthorizationCompletion = (AuthorizationResult) -> Void

enum ResponseType: String {
    case code = "code"
}

struct OpenIdAuthorizationConfig {
    let simInfo: SIMInfo
    let clientId: String
    let authorizationEndpoint: URL
    let tokenEndpoint: URL
    let formattedScopes: String
    let redirectURL: URL
    let state: String
}

private extension OpenIdAuthorizationConfig {
    var consentURLString: String {
        // NOTE: copy+past from sample code
        // I'm not certain that this is correct...
        // a) do we need this url tansformation? it seems to be for adding a custom scheme
        // when we probably want to use universal links
        // b) passing the authorization url to the app store link might make sense but I'm not sure
        return "\(authorizationEndpoint)?client_id=\(clientId.urlEncode())&response_type=code&redirect_uri=\(redirectURL.absoluteString.urlEncode())&scope=\(formattedScopes.urlEncode())"
    }
}

protocol OpenIdServiceProtocol {
    func authorize(
        fromViewController viewController: UIViewController,
        stateManager: AuthorizationStateManager,
        authorizationConifg: OpenIdAuthorizationConfig,
        completion: @escaping AuthorizationCompletion
    )
}

class OpenIdService: OpenIdServiceProtocol {
    func authorize(
        fromViewController viewController: UIViewController,
        stateManager manager: AuthorizationStateManager,
        authorizationConifg: OpenIdAuthorizationConfig,
        completion: @escaping AuthorizationCompletion
        ) {

        let openIdConfiguration = OIDServiceConfiguration(
            authorizationEndpoint: authorizationConifg.authorizationEndpoint,
            tokenEndpoint: authorizationConifg.tokenEndpoint
        )

        //create the authorization request
        let authorizationRequest: OIDAuthorizationRequest = self.createAuthorizationRequest(
            openIdServiceConfiguration: openIdConfiguration,
            authorizationConifg: authorizationConifg
        )

        // TODO: should this be `canOpenUrl` ?
        //check to see if the authorization url is set as a universal app link
        UIApplication.shared.open(
            authorizationConifg.authorizationEndpoint,
            options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: true]
        ) { success in
            if success {
                self.performCCIDAuthorization(
                    request: authorizationRequest,
                    manager: manager,
                    authorizationConifg: authorizationConifg
                )
            }
            else {
                print("Launching default safari controller process...")
                self.performSafariAuthorization(
                    request: authorizationRequest,
                    simInfo: authorizationConifg.simInfo,
                    manager: manager,
                    fromViewController: viewController,
                    completion: completion
                )
            }
        }
    }

    func createAuthorizationRequest(
        openIdServiceConfiguration: OIDServiceConfiguration,
        authorizationConifg: OpenIdAuthorizationConfig) -> OIDAuthorizationRequest {

        let request: OIDAuthorizationRequest = OIDAuthorizationRequest(
            configuration: openIdServiceConfiguration,
            clientId: authorizationConifg.clientId,
            clientSecret: nil,
            scope: authorizationConifg.formattedScopes,
            redirectURL: authorizationConifg.redirectURL,
            responseType: ResponseType.code.rawValue,
            state: authorizationConifg.state,
            nonce: nil,
            codeVerifier: nil,
            codeChallenge: nil,
            codeChallengeMethod: nil,
            additionalParameters: nil
        )

        return request
    }

    // this function will initialize the authorization request via Project Verify
    func performCCIDAuthorization(
        request: OIDAuthorizationRequest,
        manager: AuthorizationStateManager,
        authorizationConifg: OpenIdAuthorizationConfig) {

        let consentURLString = authorizationConifg.consentURLString
        print("Checking if " + consentURLString + " is part of a universal link")
        let urlTransformation = OIDExternalUserAgentIOSCustomBrowser.urlTransformationSchemeConcatPrefix(consentURLString)
        let externalUserAgent = OIDExternalUserAgentIOSCustomBrowser(
            urlTransformation: urlTransformation,
            canOpenURLScheme: nil,
            appStore: URL(string: consentURLString)
        )!

        manager.currentAuthorizationFlow = OIDAuthState.authState(
            byPresenting: request,
            externalUserAgent: externalUserAgent,
            callback: { (authState, error) in
                // TODO: it seems like we're currently swallowing completion events here and
                // omiting a symetrical completion contract. I think this could follow a single
                // flow if we trigger completion via the URL when the redirect round trips into the
                // app.
                print("authorization handed off to application")
        })
    }

    //this function will init the authstate object
    func performSafariAuthorization(
        request: OIDAuthorizationRequest,
        simInfo: SIMInfo,
        manager: AuthorizationStateManager,
        fromViewController viewController: UIViewController,
        completion: @escaping AuthorizationCompletion) {
        manager.currentAuthorizationFlow = OIDAuthState.authState(
            byPresenting: request,
            presenting: viewController,
            callback: { (authState, error) in
                guard
                    error == nil,
                    let authState = authState,
                    let authCode = authState.lastAuthorizationResponse.authorizationCode else {
                    completion(AuthorizationResult.error(error ?? UnknownError()))
                    return
                }
                let authorizedResponse = AuthorizedResponse(
                    code: authCode,
                    mcc: simInfo.identifiers.mcc,
                    mnc: simInfo.identifiers.mnc
                )
                completion(AuthorizationResult.code(authorizedResponse))
        })
    }
}

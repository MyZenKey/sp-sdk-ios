//
//  AuthorizationService.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/19/19.
//  Copyright © 2018 XCI JV, LLC. ALL RIGHTS RESERVED.
//

import AppAuth
import UIKit

public struct AuthorizationResult {
    public let code: String?

    init(code: String?) {
        self.code = code
    }
}

public class AuthorizationService {

    public typealias AuthorizationCompletion = (AuthorizationResult?, Error?) -> Void

    let sdkConfig: SDKConfig
    let discoveryService: DiscoveryServiceProtocol
    let authorizationStateManager: AuthorizationStateManager

    var openidconfiguration: OIDServiceConfiguration?

    var state: String? = ""

    init(authorizationStateManager: AuthorizationStateManager,
         sdkConfig: SDKConfig) {
        self.authorizationStateManager = authorizationStateManager
        self.sdkConfig = sdkConfig
        self.discoveryService = sdkConfig.discoveryService
    }

    public func connectWithProjectVerify(
        fromViewController viewController: UIViewController,
        completion: AuthorizationCompletion?) {

        discoveryService.discoverConfig() { [weak self] (result) in
            switch result {
            case .knownMobileNetwork(let config):
                self?.connectWithProjectVerify(
                    usingConfig: config,
                    fromViewController: viewController,
                    completion: completion
                )
            case .unknownMobileNetwork:
                // TODO: -
                break
            case .noMobileNetwork:
                // TODO: -
                break
            case .error(let error):
                // TODO: -
                break
            }
        }
    }

    private func connectWithProjectVerify(
        usingConfig carrierConfig: CarrierConfig,
        fromViewController viewController: UIViewController,
        completion: AuthorizationCompletion?) {

        // TODO: enforce carrier configuration integrity upstream so we don't need to fabricate all this inline.
        guard
            let authorizationUrlString: String = carrierConfig.openIdConfig["authorization_endpoint"],
            let tokenUrlString: String = carrierConfig.openIdConfig["token_endpoint"],
            let authorizationURL: URL = URL(string: authorizationUrlString),
            let tokenURL: URL = URL(string: tokenUrlString) else {
                fatalError("no carrier configuration found")
        }

        // TODO: remove all the force unwrapping here once we have a clear picture of failure states:
        // TODO: typed scopes
        // TODO: permit client to request scopes and omit scopes which are unsupported
        let carrierScopes = (carrierConfig.openIdConfig["scopes_supported"]!).components(separatedBy: " ")
        // TODO: should this ever not just be code?
        let carrierResponseType = carrierConfig.openIdConfig["response_types_supported"]!


        self.openidconfiguration = OIDServiceConfiguration(
            authorizationEndpoint: authorizationURL,
            tokenEndpoint: tokenURL
        )

        //create the authorization request
        guard let authorizationRequest: OIDAuthorizationRequest = self.createAuthorizationRequest(
            usingConfig: carrierConfig,
            scopes: carrierScopes,
            responseType: [carrierResponseType]) else {
                // TODO: sample code force unwraps this, handle more gracefully
                fatalError("unable to create authorization request")
        }

        print("Authorization Request created")

        // TODO: should this be `canOpenUrl` ?
        //check to see if the authorization url is set as a universal app link
        UIApplication.shared.open(
            authorizationURL,
            options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: true]
        ) { success in
            if success {
                print("This url can be opened in an app. Launching app...")
                self.performCCIDAuthorization(
                    usingConfig: carrierConfig,
                    withRequest: authorizationRequest)
            }
            else {
                print("Launching default safari controller process...")
                self.performSafariAuthorization(
                    request: authorizationRequest,
                    fromViewController: viewController,
                    completion: completion
                )
            }
        }
    }

    //this function will initialize the authorization request
    private func createAuthorizationRequest(
        usingConfig carrierConfig: CarrierConfig,
        scopes: [String],
        responseType: [String]) -> OIDAuthorizationRequest? {

        // dead code connected to commented out code below?
        //        //init extra params
        //        let extraParams:[String:String] = [String:String]()

        let request: OIDAuthorizationRequest = OIDAuthorizationRequest(
            configuration: self.openidconfiguration!,
            clientId: sdkConfig.clientId,
            clientSecret: sdkConfig.clientSecret,
            scope: "openid email profile",
            redirectURL: sdkConfig.redirectURI,
            responseType: responseType[0],
            state: "",
            nonce: nil,
            codeVerifier: nil,
            codeChallenge: nil,
            codeChallengeMethod: nil,
            additionalParameters: nil
        )
        /*let request:OIDAuthorizationRequest =  OIDAuthorizationRequest(configuration: self.openidconfiguration!, clientId: self.clientId!, scopes: self.scopes, redirectURL: redirectUrl!, responseType: responseType[0], additionalParameters: extraParams as! [String : String])*/
        request.setValue(carrierConfig.carrier.shortName.rawValue, forKeyPath: "state")
        return request
    }

    //this function will initialize the authorization request via Project Verify
    private func performCCIDAuthorization(usingConfig carrierConfig: CarrierConfig,
                                          withRequest request: OIDAuthorizationRequest) {
        //init app delegate and set the authorization flow

        let redirectURI: URL = sdkConfig.redirectURI
        let clientId: String = sdkConfig.clientId

        // TODO: guarnatee these upstream and remove force cast
        let url: String = carrierConfig.openIdConfig["authorization_endpoint"]!
        let scopes = carrierConfig.openIdConfig["scopes_supported"]!

        let consentUrlString = "\(url)?client_id=\(clientId.urlEncode())&response_type=code&redirect_uri=\(redirectURI.absoluteString.urlEncode())&scope=\(scopes.urlEncode())"
        print("Checking if " + consentUrlString + " is part of a universal link")
        let urlTransformation = OIDExternalUserAgentIOSCustomBrowser.urlTransformationSchemeConcatPrefix(consentUrlString)

        let externalUserAgent: OIDExternalUserAgentIOSCustomBrowser = OIDExternalUserAgentIOSCustomBrowser(
            urlTransformation: urlTransformation,
            canOpenURLScheme: nil,
            appStore: URL(string: consentUrlString)
            )!

        authorizationStateManager.currentAuthorizationFlow = OIDAuthState.authState(
            byPresenting: request,
            externalUserAgent:externalUserAgent,
            callback: { (authState, error) in
                // TODO: it seems like we're currently swallowing completion events here and
                // omiting a symetrical completion contract. I think this could follow a single
                // flow if we trigger completion via the URL when the redirect round trips into the
                // app.
                print("authorization handed off to application")
        })
    }

    //this function will init the authstate object
    private func performSafariAuthorization(
        request: OIDAuthorizationRequest,
        fromViewController viewController: UIViewController,
        completion: AuthorizationCompletion?) {
        print("Making Authorization Request")
        authorizationStateManager.currentAuthorizationFlow = OIDAuthState.authState(
            byPresenting: request,
            presenting: viewController,
            callback: { (authState, error) in
                guard error == nil else { completion?(nil, error); return; }
                let authCode = authState?.lastAuthorizationResponse.authorizationCode
                completion?(AuthorizationResult(code: authCode), nil)
        })
    }
}

public extension AuthorizationService {
    convenience init() {
        // use AppDelegate as a dependency container until we have a clearer idea of what we want
        let appDelegate = ProjectVerifyAppDelegate.shared
        self.init(authorizationStateManager: appDelegate,
                  sdkConfig: appDelegate.sdkConfig)
    }
}

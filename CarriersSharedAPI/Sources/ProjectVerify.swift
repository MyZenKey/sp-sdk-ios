//
//  ProjectVerify.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/13/19.
//  Copyright © 2019 Rightpoint. All rights reserved.
//

import AppAuth
import UIKit

class SDKConfig {
    enum PlistKeys {
        static let ClientId = "ProjectVerifyClientId"
        static let ClientSecret = "ProjectVerifyClientSecret"
    }

    let sharedAPI = SharedAPI()

    private(set) var clientId: String!
    private(set) var clientSecret: String!

    lazy var carrierConfig: [String: Any]? = {
        return sharedAPI.discoverCarrierConfiguration()
    }()

    func loadFromBundle() {
        guard
            let clientId = Bundle.main.infoDictionary?[PlistKeys.ClientId] as? String,
            let clientSecret = Bundle.main.infoDictionary?[PlistKeys.ClientId] as? String else {
                fatalError("""
                    Please configure the following keys in your App's info plist:
                    \(PlistKeys.ClientId), \(PlistKeys.ClientSecret)
                    """)
        }

        self.clientId = clientId
        self.clientSecret = clientSecret
    }
}

public class ProjectVerifyAppDelegate {

    public static let shared = ProjectVerifyAppDelegate()

    let sdkConfig = SDKConfig()

    var openidconfiguration: OIDServiceConfiguration?
    var carrier: String?
    var state: String? = ""
    var redirectUri: String? = "com.att.ent.cso.haloc.bankapp://code"
    var sharedAPI: SharedAPI?
    var carrierConfig: [String:Any]? = nil
    var scopes: [String]? = nil
    var responseTypes: [String]? = nil

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        // initialize sdk config
        sdkConfig.loadFromBundle()
    }

    public func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {

        // TODO:
        return true
    }
}

public class Authentication {

    let sdkConfig: SDKConfig
    let scopes: [String]
    var responseTypes: [String]
    var openidconfiguration: OIDServiceConfiguration?


    var carrier: String?
    var clientId: String? = "BankApp"
    var secret: String? = "bankapp_client_secret"
    var state: String? = ""
    var redirectUri: String? = "com.att.ent.cso.haloc.bankapp://code"

    init(sdkConfig: SDKConfig) {
        self.sdkConfig = sdkConfig
        // TODO: remove all the force unwrapping here once we have a clear picture of failure states:
        self.scopes = (sdkConfig.carrierConfig!["scopes_supported"] as! String).components(separatedBy: " ")
        self.responseTypes = [sdkConfig.carrierConfig!["response_types_supported"]! as! String]
    }

    public func connectWithProjectVerify() {
        // NOTE: we're force casting above so this will never not be present (we'll have crashed) we should
        // follow a secondary device flow in the future once we've cleaned this up:
        guard let carrierConfig = sdkConfig.carrierConfig else {
            fatalError("no carrier configuration found")
        }

        // TODO: enforce carrier configuration integrity upstream so we don't need to fabricate all this inline.
        guard
            let authorizationUrlString: String = carrierConfig["authorization_endpoint"] as? String,
            let tokenUrlString: String = carrierConfig["token_endpoint"] as? String,
            let authorizationURL: URL = URL(string: authorizationUrlString),
            let tokenURL: URL = URL(string: tokenUrlString) else {
                fatalError("no carrier configuration found")
        }

        self.openidconfiguration = OIDServiceConfiguration(
            authorizationEndpoint: authorizationURL,
            tokenEndpoint: tokenURL
        )


        //create the authorization request
        guard let authorizationRequest: OIDAuthorizationRequest = self.createAuthorizationRequest(
            scopes: scopes,
            responseType: responseTypes) else {
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
                self.initProjectVerifyAuthorization(request: authorizationRequest)
            }
            else {
                print("Launching default safari controller process...")
                self.performAuthorization(request: authorizationRequest)
            }
        }
    }

    //this function will initialize the authorization request
    func createAuthorizationRequest(scopes: [String], responseType: [String]) -> OIDAuthorizationRequest? {

        //init the authorization redirect
        let redirectUrl:URL? = URL(string: self.redirectUri!) as! URL

        //init extra params
        let extraParams:[String:String] = [String:String]()

        //compile request
        do {
            let request:OIDAuthorizationRequest = OIDAuthorizationRequest.init(configuration: self.openidconfiguration!, clientId: self.clientId!, clientSecret: self.secret, scope: "openid email profile", redirectURL: redirectUrl, responseType: responseType[0], state: "", nonce: nil, codeVerifier: nil, codeChallenge: nil, codeChallengeMethod: nil, additionalParameters: nil)
            /*let request:OIDAuthorizationRequest =  OIDAuthorizationRequest(configuration: self.openidconfiguration!, clientId: self.clientId!, scopes: self.scopes, redirectURL: redirectUrl!, responseType: responseType[0], additionalParameters: extraParams as! [String : String])*/
            request.setValue(sharedAPI!.carrierName, forKeyPath: "state")
            return request
        }
        catch let error {
            print("Error occurred - \(error)")
        }
        return nil
    }

    //this function will initialize the authorization request via Project Verify
    func initProjectVerifyAuthorization(request: OIDAuthorizationRequest) {
        //init app delegate and set the authorization flow
        var url:String = self.carrierConfig!["authorization_endpoint"] as! String
        var scopes = self.carrierConfig!["scopes_supported"] as! String
        let consentUrlString = "\(url)?client_id=\(clientId!.urlEncode())&response_type=code&redirect_uri=\(redirectUri!.urlEncode())&scope=\(scopes.urlEncode())"
        print("Checking if " + consentUrlString + " is part of a universal link")
        var optionalUrl:Optional<URL> = URL(string:consentUrlString)
        var urlTransformation = OIDExternalUserAgentIOSCustomBrowser.urlTransformationSchemeConcatPrefix(consentUrlString)
        let externalUserAgent:OIDExternalUserAgentIOSCustomBrowser = OIDExternalUserAgentIOSCustomBrowser.init(urlTransformation: urlTransformation, canOpenURLScheme: nil, appStore: URL(string: consentUrlString))!
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, externalUserAgent:externalUserAgent, callback: { (authState, error) in
            print("authorization handed off to application")
        })
    }

    //this function will init the authstate object
    func performAuthorization(request: OIDAuthorizationRequest) {
        print("Making Authorization Request")

        //init app delegate and set the authorization flow
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: self, callback: { (authState, error) in
            print("Authorization callback has completed")
            if(error == nil) {
                print("Authentication passed. Redirecting to UserInfoViewController")
                let authorizationCode = authState!.lastAuthorizationResponse.authorizationCode
                var accessToken = authState?.lastTokenResponse?.accessToken
                print("Authentication passed. Extracting access token - " + accessToken!)

                //perform a simple GET request to gather the user information
                let userInfoUrl = URL(string: self.carrierConfig!["userinfo_endpoint"] as! String)
                let request = NSMutableURLRequest(url: userInfoUrl! as URL)
                request.httpMethod = "GET"
                request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
                let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
                    print("User information response has returned - ")
                    if(error == nil) {
                        if let res = response as? HTTPURLResponse {
                            print(res)
                            let responseString = String(data: data!, encoding:String.Encoding.utf8) as String!
                            print(responseString)

                            do{
                                //convert the json string to pure json
                                if let json = responseString!.data(using: String.Encoding.utf8){
                                    var jsonDocument:JsonDocument = JsonDocument(data: json)
                                    //perform async task to update UI
                                    DispatchQueue.main.async {
                                        let appDelegate = UIApplication.shared.delegate as? AppDelegate
                                        appDelegate?.launchHomeScreen()
                                    }
                                }
                            }catch {
                                print(error.localizedDescription)

                            }
                        }
                    }
                    else {
                        print(error)
                    }
                }
                task.resume()
            }
            else {
                print("Authorization failed - " + error.debugDescription)
            }
        })
    }
}

//
//  ProjectVerify.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/13/19.
//  Copyright © 2019 Rightpoint. All rights reserved.
//

import AppAuth
import UIKit

protocol AuthorizationStateManager: AnyObject {
    var currentAuthorizationFlow: OIDExternalUserAgentSession? { get set }
}

public class ProjectVerifyAppDelegate: AuthorizationStateManager {

    public static let shared = ProjectVerifyAppDelegate()

    var currentAuthorizationFlow: OIDExternalUserAgentSession?

    let sdkConfig = SDKConfig()

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        // initialize sdk config
        sdkConfig.loadFromBundle(bundle: Bundle.main)
    }

    public func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {

        guard
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let queryItems = urlComponents.queryItems else {
                return false
        }

        // concluding an auth flow:
        if queryItems.first(where: { $0.name == "code" }) != nil {
            // NOTE: this parsing, using `resumeExternalUserAgentFlow` is not the initial
            // implementation from the example apps but seems to be the
            // correct implementation from the AppAuth docs. need to figure out why this was not
            // the case initially
            if currentAuthorizationFlow?.resumeExternalUserAgentFlow(with: url) ?? false {
                currentAuthorizationFlow = nil
                return true
            }
        }

        // TODO: - We don't have a spec for other states that might be resolved via this url.
        // add those here when we do

        // unhandled
        return false
    }
}

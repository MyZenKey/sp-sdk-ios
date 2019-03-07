//
//  ProjectVerify.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/13/19.
//  Copyright © 2018 XCI JV, LLC. ALL RIGHTS RESERVED.
//

import AppAuth
import UIKit

public class ProjectVerifyAppDelegate {

    public static let shared = ProjectVerifyAppDelegate()

    let dependencies: DependenciesProtocol = Dependencies()

    private(set) var sdkConfig = SDKConfig()

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        // initialize sdk config
        self.sdkConfig = SDKConfigLoader.loadFromBundle(bundle: Bundle.main)
    }

    public func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {

        // This scheme is project verify specifc and any requests sent to this scheme should be
        // handled by us.
        guard url.scheme == sdkConfig.redirectURL.scheme else {
            return false
        }

        // concluding an auth flow:
        dependencies.openIdService.concludeAuthorizationFlow(url: url)

        // TODO: - We don't have a spec for other states that might be resolved via this url.
        // add those here when we do

        // unhandled
        return false
    }
}

//
//  ProjectVerify.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/13/19.
//  Copyright © 2018 XCI JV, LLC. ALL RIGHTS RESERVED.
//

import UIKit

/// This class represents the entry point for the application and mirrors the behavior of
/// UIApplication's UIApplicationDelegate type. This property should be accessed via its `shared`
/// singleton instance to ensure there is only one instance per application. There are two methods
/// that consumers are responsible for forwarding in the UIApplicationDelegate type:
/// `application(_:didFinishLaunchingWithOptions:)`
/// and
/// `application(_:open:options)`
///
/// - SeeAlso: UIApplicationDelegate
public class ProjectVerifyAppDelegate {

    /// The shared `ProjectVerifyAppDelegate` instance.
    ///
    /// This should be the only instance of the `ProjectVerifyAppDelegate` used. Creation of other
    /// instances is unsupported.
    public static let shared = ProjectVerifyAppDelegate()

    private(set) var dependencies: Dependencies!

    private var discoveryService: DiscoveryServiceProtocol!
    

    /// The entry point for the ProjectVerifyLogin SDK. You should call this method during your
    /// applicaiton's `application(_:didFinishLaunchingWithOptions:)` method before returning.
    ///
    /// - Parameters:
    ///   - application: The UIApplication instance received by your application's app
    ///     delegate
    ///   - launchOptions: The launchOptions received by your applicaiton's app delegate
    ///   - projectVerifyOptions: Project verify specific options.
    ///
    /// This method is responsible for configuring the ProjectVerifyLogin SDK and should be called
    /// before performing any other actions with the SDK.
    ///
    /// - SeeAlso: UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)
    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        projectVerifyOptions: ProjectVerifyOptions = [:]) {
        // initialize sdk config
        do {
            let sdkConfig = try SDKConfig.load(fromBundle: Bundle.main)
            self.dependencies = Dependencies(sdkConfig: sdkConfig, options: projectVerifyOptions)
            let discoveryService: DiscoveryServiceProtocol = self.dependencies.resolve()
            self.discoveryService = discoveryService
            prefetchOIDC()
        } catch {
            fatalError("Bundle configuration error: \(error)")
        }
    }

    /// Call this method in your application delegates's `application(_:open:options)` method.
    /// This provides `ProjectVerifyLogin` the opportunity to handle the inbound URL.
    ///
    /// - Parameters:
    ///   - application: The UIApplication instance received by your application's app
    ///     delegate
    ///   - url: The URL parameter received by your applications app delegate
    ///   - options: The options received by your applicaiton's app delegate
    ///
    /// - Returns: a boolean indicating true if `ProjectVerifyLogin` successfully handled the url
    /// passed into it, or `false`, if the URL remains un-handled.
    ///
    /// - SeeAlso: UIApplicationDelegate.application(_:open:options)`
    public func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {

        // This scheme is project verify specifc and any requests sent to this scheme should be
        // handled by us.
        guard url.scheme == dependencies.sdkConfig.redirectScheme else {
            return false
        }

        guard let currentAuthorizationService =
            AuthorizationServiceCurrentRequestStorage.shared.currentRequestingService else {
            return false
        }

        return currentAuthorizationService.resolve(url: url)
    }
}

private extension ProjectVerifyAppDelegate {
    func prefetchOIDC() {
        let currentDeviceInfo: CarrierInfoServiceProtocol = dependencies.resolve()
        guard let simInfo = currentDeviceInfo.primarySIM else {
            Log.log(.verbose, "Skipping prefetch of discovery: No SIM info")
            return
        }

        Log.log(.verbose, "Prefetching discovery")
        discoveryService.discoverConfig(
            forSIMInfo: simInfo,
            prompt: false
        ) { _ in  /* fail silently, prefetch is best effort only */ }
    }
}

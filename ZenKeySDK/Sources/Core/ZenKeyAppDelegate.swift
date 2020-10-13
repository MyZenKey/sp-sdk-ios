//
//  ZenKey.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/13/19.
//  Copyright © 2019-2020 ZenKey, LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

/// This class represents the entry point for the application and mirrors the behavior of
/// UIApplication's UIApplicationDelegate type. This property should be accessed via its `shared`
/// singleton instance to ensure there is only one instance per application.
///
/// There are two methods
/// that consumers are responsible for forwarding in the UIApplicationDelegate type:
///
/// `application(_:didFinishLaunchingWithOptions:)`
///
/// `application(_:open:options)`
///
/// - SeeAlso: UIApplicationDelegate
public class ZenKeyAppDelegate {

    /// The shared `ZenKeyAppDelegate` instance.
    ///
    /// This should be the only instance of the `ZenKeyAppDelegate` used. Creation of other
    /// instances is unsupported.
    public static let shared = ZenKeyAppDelegate()

    #if TARGET_INTERFACE_BUILDER
    private(set) var dependencies = Dependencies(sdkConfig: SDKConfig())
    #else
    private(set) var dependencies: Dependencies!
    #endif

    private var discoveryService: DiscoveryServiceProtocol!

    /// The entry point for the ZenKey SDK. You should call this method during your
    /// application's `application(_:didFinishLaunchingWithOptions:)` method before returning.
    ///
    /// - Parameters:
    ///   - application: The UIApplication instance received by your application's AppDelegate
    ///   - launchOptions: The launchOptions received by your application's AppDelegate
    ///   - zenKeyOptions: ZenKey specific options.
    ///
    /// This method is responsible for configuring the ZenKey SDK and should be called
    /// before performing any other actions with the SDK.
    ///
    /// - SeeAlso: `UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)`
    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        zenKeyOptions: ZenKeyOptions = [:]) {
        // Initialize ZenKey SDK config
        do {
            let sdkConfig = try SDKConfig.load(fromBundle: Bundle.main)
            self.dependencies = Dependencies(sdkConfig: sdkConfig, options: zenKeyOptions)
            self.discoveryService = self.dependencies.resolve()
            prefetchOIDC()
        } catch {

            fatalError("Bundle configuration error: \(error)")
        }
    }

    /// Call this method in your AppDelegate's `application(_:open:options:)` method.
    /// This provides the ZenKey SDK the opportunity to handle the inbound URL.
    ///
    /// This method's return value allows you to easily skip your app's URL handling if a
    /// ZenKey URL is successfully handled:
    ///
    /// ```swift
    /// if ZenKeyAppDelegate.shared.application(app, open: url, options: options) {
    ///     // ZenKey has successfully processed the redirect.
    ///     return true
    /// }
    ///
    /// // Perform any other URL processing your app may need.
    ///
    /// return false
    /// ```
    ///
    /// - Parameters:
    ///   - application: The UIApplication instance received by your application's AppDelegate
    ///   - url: The URL parameter received by your application's AppDelegate
    ///   - options: The options received by your application's AppDelegate
    ///
    /// - Returns: A boolean indicating `true` if the ZenKey SDK successfully handled the url
    /// passed into it, or `false`, if the URL remains unhandled.
    ///
    /// - SeeAlso: `UIApplicationDelegate.application(_:open:options)`
    public func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {

        // This scheme is ZenKey specific and any requests sent to this scheme should be
        // handled by the ZenKey SDK.
        guard url.scheme == dependencies.sdkConfig.redirectScheme else {
            return false
        }

        guard let currentAuthorizationService =
            AuthorizationServiceCurrentRequestStorage.shared.currentRequestingService else {
            // swiftlint:disable:next line_length
            Log.log(.error, "Cannot complete auth. This may be caused by the app being killed before auth was complete, or because you have multiple apps installed using the same client_id.")
            showErrorAlert(Localization.Errors.incomingRequest)
            return false
        }

        return currentAuthorizationService.resolve(url: url)
    }
}

private extension ZenKeyAppDelegate {
    func prefetchOIDC() {
        let currentDeviceInfo: CarrierInfoServiceProtocol = dependencies.resolve()
        guard let simInfo = currentDeviceInfo.primarySIM else {
            Log.log(.verbose, "Skipping prefetch of discovery: No SIM info")
            return
        }

        Log.log(.verbose, "Pre-fetching discovery")
        discoveryService.discoverConfig(
            forSIMInfo: simInfo,
            prompt: false
        ) { _ in  /* fail silently, prefetch is best effort only */ }
    }

    private func showErrorAlert(_ message: String) {
        guard let controller = UIViewController.currentController else {
            Log.log(.verbose, "No view controller available for error alert")
            return
        }

        let alert = UIAlertController(
            title: Localization.Alerts.error,
            message: message,
            preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(
            title: Localization.Alerts.okay,
            style: UIAlertAction.Style.default,
            handler: nil))
        controller.present(alert, animated: true, completion: nil)
    }
}

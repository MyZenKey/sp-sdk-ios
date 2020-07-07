//
//  ZenKeySceneDelegate.swift
//  ZenKeySDK
//
//  Created by Kyle Alan Hale on 6/3/20.
//  Copyright © 2020 ZenKey, LLC.
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

import Foundation

/// This class represents the entry point for the application and mirrors the behavior of
/// UIApplication's UIWindowSceneDelegate type. This property should be accessed via its `shared`
/// singleton instance to ensure there is only one instance per application.
///
/// There is one method
/// that consumers are responsible for forwarding in the UIApplicationDelegate type:
///
/// `scene(_:openURLContexts:)`
///
/// - SeeAlso: UIWindowSceneDelegate
@available(iOS 13.0, *)
public class ZenKeySceneDelegate {

    /// The shared `ZenKeySceneDelegate` instance.
    ///
    /// This should be the only instance of the `ZenKeySceneDelegate` used. Creation of other
    /// instances is unsupported.
    public static let shared = ZenKeySceneDelegate()

    /// Call this method in your SceneDelegate's `scene(_:willConnectTo:options:)` method.
    ///
    /// ZenKey URL handling is deferred in this method, so no indication is provided of
    /// which URLs remain unhandled. You should take steps to ensure that you only handle your
    /// own URLs in your SceneDelegate's `scene(_:willConnectTo:options:)`.
    ///
    /// - Parameters:
    ///   - scene: The current UIScene instance received by your application's SceneDelegate
    ///   - session: The scene session received by your application's SceneDelegate
    ///   - options: The connection options received by your application's SceneDelegate,
    ///       which contains the URL contexts to handle
    ///
    /// - SeeAlso: `UIWindowSceneDelegate.scene(_:willConnectTo:options:)`
    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard connectionOptions.urlContexts.count > 0 else { return }

        var observer: NSObjectProtocol?
        observer = NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: OperationQueue.main) { [weak self] _ in
            // Forward contexts on to be handled as usual
            _ = self?.scene(scene, openURLContexts: connectionOptions.urlContexts)
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }

    /// Call this method in your SceneDelegate's `scene(_:openURLContexts:)` method.
    /// This provides the ZenKey SDK the opportunity to handle the inbound URL.
    ///
    /// This method's return value allows you to easily filter out ZenKey URLs
    /// for your own app's URL handling:
    ///
    /// ```swift
    /// let unhandledContexts = ZenKeySceneDelegate.shared.scene(scene, openURLContexts: URLContexts)
    /// unhandledContexts.forEach { context in
    ///     // Handle context
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - scene: The current UIScene instance received by your application's SceneDelegate
    ///   - openURLContexts: The URL contexts received by your application's SceneDelegate
    ///
    /// - Returns: A set of contexts for the URLs that remain unhandled by the ZenKey SDK.
    ///
    /// - SeeAlso: `UIWindowSceneDelegate.scene(_:openURLContexts:)`
    public func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>) -> Set<UIOpenURLContext> {
        // Filter out successfully handled URLs
        return URLContexts.filter { context in
            return !ZenKeyAppDelegate.shared.application(UIApplication.shared, open: context.url)
        }
    }
}

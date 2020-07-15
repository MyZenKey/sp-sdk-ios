//
//  AppDelegate.swift
//  ZenKeySDK
//
//  Created by Sawyer Billings on 2/18/20.
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

import UIKit
import LocalAuthentication
import ZenKeySDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let signInService = SignInService()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        //
        // ZENKEY SDK
        // You must instantiate ZenKey in the AppDelegate as follows:
        //
        ZenKeyAppDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )

        self.window = UIWindow(frame: UIScreen.main.bounds)

        let signInVC = SignInViewController(service: signInService)
        let nav = UINavigationController(rootViewController: signInVC)

        self.window?.rootViewController = nav
        self.window?.makeKeyAndVisible()

        checkDeviceLockStatus()
        checkDeviceJailbreakStatus()

        return true
    }

    func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        // Disable third-party keyboards if your app allows users to type sensitive data
        if extensionPointIdentifier == .keyboard {
            return false
        }
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        //
        // ZENKEY SDK
        // You must let ZenKey handle redirects:
        //
        if ZenKeyAppDelegate.shared.application(app, open: url, options: options) {
            // ZenKey has successfully processed the redirect.
            return true
        }

        // Perform any other URL processing your app may need.

        return false
    }

}

extension AppDelegate {
    func checkDeviceLockStatus() {
        let deviceWillLock = LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        if !deviceWillLock {
            // If your app stores sensitive data, you may want to confirm that the user's device is
            // protected by at least a passcode.
            showErrorAlert(Localized.Error.Startup.unprotected, completion: checkDeviceLockStatus)
        }
    }

    func checkDeviceJailbreakStatus() {
        let canWriteToPrivate = (try? "Jailbreak test".write(toFile: "/private/test jailbreak", atomically: true, encoding: .utf8)) != nil

        let deviceIsJailbroken =
            canWriteToPrivate ||
            FileManager.default.fileExists(atPath: "/Applications/Cydia.app") ||
            FileManager.default.fileExists(atPath: "/Library/MobileSubstrate/MobileSubstrate.dylib") ||
            FileManager.default.fileExists(atPath: "/etc/apt") ||
            FileManager.default.fileExists(atPath: "/private/var/lib/apt") ||
            UIApplication.shared.canOpenURL(URL(string: "cydia://package/com.example.package")!)

        if deviceIsJailbroken {
            // If your app stores sensitive data, you may want to confirm that the user's device is
            // not jailbroken.
            showErrorAlert(Localized.Error.Startup.jailbroken, completion: checkDeviceJailbreakStatus)
        }
    }
}

extension AppDelegate {
    private func showErrorAlert(_ message: String, completion: @escaping (() -> ())) {
        guard let controller = self.window?.rootViewController else { return }

        let alert = UIAlertController(
            title: Localized.Alert.errorTitle,
            message: message,
            preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(
            title: Localized.Alert.ok,
            style: UIAlertAction.Style.default,
            handler: { _ in completion() }))
        controller.present(alert, animated: true, completion: nil)
    }
}

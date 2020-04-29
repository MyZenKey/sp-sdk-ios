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

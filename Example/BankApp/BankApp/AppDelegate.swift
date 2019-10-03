//
//  AppDelegate.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import ZenKeySDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, DemoAppAppDelegate {

    var window: UIWindow?
    private(set) var router: BankAppRouter!
    private var serviceAPI: ServiceProviderAPIProtocol = BuildInfo.serviceProviderAPI()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        UITestLaunchArgument.handle()

        ZenKeyAppDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions,
            zenKeyOptions: BuildInfo.zenKeyOptions
        )

        window = UIWindow(frame: UIScreen.main.bounds)
        
        guard let window = window else {
            fatalError("unable to make window")
        }

        self.router = BankAppRouter(window: window)
        if AccountManager.isLoggedIn {
            router.startAppFlow()
        } else {
            router.startLoginFlow()
        }
        window.makeKeyAndVisible()

        NavigationBarAppearance.configureNavBar()

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {

        guard !ZenKeyAppDelegate.shared.application(app, open: url, options: options) else {
            return true
        }

        return true
    }

    func logout() {
        serviceAPI.logout { [weak self] _ in
            AccountManager.logout()
            self?.router.startLoginFlow()
        }
    }
}

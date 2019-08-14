//
//  AppDelegate.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import CarriersSharedAPI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, DemoAppAppDelegate {
    var window: UIWindow?
    var navigationController: UINavigationController?
    var launchMapViewFlag: Bool = true

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        ProjectVerifyAppDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions,
            projectVerifyOptions: BuildInfo.projectVerifyOptions
        )

        window = UIWindow(frame: UIScreen.main.bounds)

        if let window = window {

            let mainVC: UIViewController
            if AccountManager.isLoggedIn {
                mainVC = UserInfoViewController()
            } else {
                mainVC = LandingViewController()
            }
            navigationController = UINavigationController(rootViewController: mainVC)
            navigationController?.isNavigationBarHidden = true
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
        }
        
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
        return ProjectVerifyAppDelegate.shared.application(app, open: url, options: options)
    }

    func launchMapScreen(token: String) {
        let vc = UserInfoViewController()

        navigationController = UINavigationController(rootViewController: vc)
        navigationController?.isNavigationBarHidden = true
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
    
    func launchSignUpScreen(token: String) {
        let vc = SignUpViewController()
        navigationController = UINavigationController(rootViewController: vc)
        navigationController?.isNavigationBarHidden = true
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            //present the view controller
            topController.present(vc, animated: true)
        }
    }
    
    func logout() {
        AccountManager.logout()
        launchLoginScreen()
    }
    
    func launchLoginScreen() {
        navigationController = UINavigationController(rootViewController: LandingViewController())
        navigationController?.isNavigationBarHidden = true
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
}

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
    private var serviceAPI: ServiceAPIProtocol = ClientSideServiceAPI()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        UITestLaunchArgument.handle()

        ProjectVerifyAppDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions,
            projectVerifyOptions: BuildInfo.projectVerifyOptions
        )

        // Override point for customization after application launch.
        let _ = launchTransferCompleteScreenIfNeeded()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        if let window = window {

            let mainVC: UIViewController
            if AccountManager.isLoggedIn {
                mainVC = HomeViewController()
            } else {
                mainVC = LoginViewController()
            }
            navigationController = UINavigationController(rootViewController: mainVC)
            navigationController?.isNavigationBarHidden = true
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("Application will resign active.")
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("Application did enter background.")
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        let _ = launchTransferCompleteScreenIfNeeded()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("Application will terminate.")
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {

        guard !ProjectVerifyAppDelegate.shared.application(app, open: url, options: options) else {
            return true
        }

        return true
    }

    func logout() {
        serviceAPI.logout { [weak self] _ in
            AccountManager.logout()
            self?.launchLoginScreen()
        }
    }

    // MARK: Launch root screen flows
    
    func launchHomeScreen() {
        let transferCompleteVC = HomeViewController()
        navigationController = UINavigationController(rootViewController: transferCompleteVC)
        navigationController?.isNavigationBarHidden = true
        self.window?.rootViewController = navigationController
    }
    
    func launchTransferCompleteScreen() {
        let transferCompleteVC = ApproveViewController()
        navigationController = UINavigationController(rootViewController: transferCompleteVC)
        navigationController?.isNavigationBarHidden = true
        self.window?.rootViewController = navigationController
    }

    func launchLoginScreen() {
        let loginVC = LoginViewController()
        navigationController = UINavigationController(rootViewController: loginVC)
        navigationController?.isNavigationBarHidden = true
        self.window?.rootViewController = navigationController
    }
    
    func launchTransferCompleteScreenIfNeeded() -> Bool {
        if UserDefaults.standard.bool(forKey: "initiatedTransfer") {
            DispatchQueue.main.async { [weak self] in
                UserDefaults.standard.set(false, forKey: "initiatedTransfer")
                UserDefaults.standard.synchronize()
                if !UserDefaults.standard.bool(forKey: "transaction_denied"){
                    self?.launchTransferCompleteScreen()
                }
            }
            return true
        }
        return false
    }
}


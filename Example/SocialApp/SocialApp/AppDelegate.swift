//
//  AppDelegate.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import CarriersSharedAPI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var navigationController: UINavigationController?
    var launchMapViewFlag: Bool = true

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        ProjectVerifyAppDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )

        window = UIWindow(frame: UIScreen.main.bounds)
        
        if let window = window {
            let mainVC = ViewController()
            navigationController = UINavigationController(rootViewController: mainVC)
            navigationController?.isNavigationBarHidden = true
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
        }
        
        return true
    }

    /// Tells the delegate that the data for continuing an activity is available.
    ///
    /// - Parameters:
    ///   - application: The shared app object that controls and coordinates your app.
    ///   - userActivity: The activity object containing the data associated with the task the user was performing. Use the data to continue the user's activity in your iOS app.
    ///   - restorationHandler: A block to execute if your app creates objects to perform the task. Calling this block is optional.
    /// - Returns: true to indicate that your app handled the activity or false to let iOS know that your app did not handle the activity.
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Swift.Void) -> Bool {

        // TODO: There isn't a use case for this yet – re-enable this if one emerges
//        print("Universal link attempt detected: \(String(describing: userActivity.webpageURL))")
//
//        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
//            guard let url = userActivity.webpageURL else { return false }
//
//            let vc = UserInfoViewController()
//            vc.url = url
//
//            navigationController = UINavigationController(rootViewController: vc)
//            navigationController?.isNavigationBarHidden = true
//            window?.rootViewController = navigationController
//            window?.makeKeyAndVisible()
//
//            return true
//        }

        return false
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
        print("Launching application from universal link")
        return ProjectVerifyAppDelegate.shared.application(app, open: url, options: options)
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
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("Application will terminate.")
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func launchMapScreen(code: String) {
        let vc = UserInfoViewController()
        vc.code = code
        
        navigationController = UINavigationController(rootViewController: vc)
        navigationController?.isNavigationBarHidden = true
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
    
    func launchSignUpScreen(code: String) {
        print("Launching signup screen")
        let vc = SignUpViewController()
        vc.code = code
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
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.resetStandardUserDefaults()
        
        let dictionary = UserDefaults.standard.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
        
        NSLog("Reset UserDefaults is successful")
        launchLoginScreen()
    }
    
    func launchLoginScreen() {
        print("Launching login screen")
        navigationController = UINavigationController(rootViewController: ViewController())
        navigationController?.isNavigationBarHidden = true
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
}


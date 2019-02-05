//
//  AppDelegate.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import AppAuth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var navigationController: UINavigationController?
    var launchMapViewFlag: Bool = true
    var currentAuthorizationFlow:OIDExternalUserAgentSession?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let _ = launchTransferCompleteScreenIfNeeded()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        if let window = window {
            let mainVC = LoginViewController()
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

    // MARK: Universal linking
    
    /// Tells the delegate that the data for continuing an activity is available.
    ///
    /// - Parameters:
    ///   - application: The shared app object that controls and coordinates your app.
    ///   - userActivity: The activity object containing the data associated with the task the user was performing. Use the data to continue the user's activity in your iOS app.
    ///   - restorationHandler: A block to execute if your app creates objects to perform the task. Calling this block is optional.
    /// - Returns: true to indicate that your app handled the activity or false to let iOS know that your app did not handle the activity.
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Swift.Void) -> Bool {
        
        print("Universal link attempt detected: \(String(describing: userActivity.webpageURL))")
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            //guard let url = userActivity.webpageURL else { return false }
            
            launchHomeScreen()
            
            return true
        }
        
        return false
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
        
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if components.host == "transaction_completed" {
                // Show the transaction completed screen
                launchTransferCompleteScreen()
            } else if components.host == "transaction_denied" {
                // Log out to login screen
                UserDefaults.standard.set(true, forKey: "transaction_denied");
                UserDefaults.standard.synchronize();
                
                launchLoginScreen()
            } else if let AuthZ_Code = (components.queryItems?.filter({ (item) in item.name == "code" }).first?.value) {
                
                print("AuthZ_Code value from \(String(describing: url.scheme)) scheme is: \(AuthZ_Code)\n")
                
                UserDefaults.standard.set(AuthZ_Code,forKey: "AuthZCode")
                UserDefaults.standard.synchronize();
                
                // Launching Correct Screen based on previous call using launchMapViewFlag (Need to comeup with better idea later)
                
                launchHomeScreen()
            } else if !launchTransferCompleteScreenIfNeeded() {
                launchLoginScreen()
            }
        } else if !launchTransferCompleteScreenIfNeeded() {
            launchLoginScreen()
        }
        
        return true
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
    
    func logout() {
       
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


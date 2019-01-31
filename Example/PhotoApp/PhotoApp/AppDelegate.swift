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
    var currentAuthorizationFlow:OIDExternalUserAgentSession?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
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
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        print("App opening with contextual deep link: URL -> \(url)")
        
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if let AuthZ_Code = (components.queryItems?.filter({ (item) in item.name == "code" }).first?.value) {
                
                print("AuthZ_Code value from \(String(describing: url.scheme)) scheme is: \(AuthZ_Code)\n")
       
                UserDefaults.standard.set(AuthZ_Code,forKey: "AuthZCode")
                UserDefaults.standard.synchronize();
                
                launchCheckOutScreen(url: url)
                
            } else {
              launchLoginScreen()
            }
        }
        return true
        
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
        let storyboard = UIStoryboard(name:"Main", bundle: nil)
        let loginVC = storyboard.instantiateInitialViewController()
        self.window?.rootViewController = loginVC
    }
    func launchCheckOutScreen(url: URL) {
        
        let checkOutNavVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CheckoutNavViewController") as! UINavigationController
        let checkOutVC = checkOutNavVC.topViewController as! CheckoutViewController
        checkOutVC.url = url
        
        UIApplication.shared.keyWindow?.rootViewController?.present(checkOutNavVC, animated: true, completion: nil)

    }
    
}


//
//  UIViewController+Helpers.swift
//  BankApp
//
//  Created by Adam Tierney on 6/26/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import UIKit
import CarriersSharedAPI

// MARK: - View Helpers

extension UIViewController {
    struct Constants {
        static var gradientHeaderHeight: CGFloat {
            let base: CGFloat = 70
            if #available(iOS 11.0, *) {
                return base
            } else {
                // before ios 11, account for status bar (automatically accounted for in safe area)
                return  base + UIApplication.shared.statusBarFrame.height
            }
        }
    }
}

// MARK: - Navigation

extension UIViewController {
    func launchHomeScreen() {
        // TODO: - fix this up, shouldn't be digging into app delegate but quickest refactor
        let appDelegate = UIApplication.shared.delegate! as! AppDelegate
        appDelegate.launchHomeScreen()
    }

    func launchLoginScreen() {
        // TODO: - fix this up, shouldn't be digging into app delegate but quickest refactor
        let appDelegate = UIApplication.shared.delegate! as! AppDelegate
        appDelegate.launchLoginScreen()
    }
}

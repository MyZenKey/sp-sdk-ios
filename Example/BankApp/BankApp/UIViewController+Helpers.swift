//
//  UIViewController+Helpers.swift
//  BankApp
//
//  Created by Adam Tierney on 6/26/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import UIKit
import ZenKeySDK

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
    var sharedRouter: BankAppRouter {
        return (UIApplication.shared.delegate! as! AppDelegate).router
    }
}

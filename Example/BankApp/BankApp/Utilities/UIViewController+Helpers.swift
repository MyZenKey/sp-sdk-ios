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

    static func makeDemoPurposesLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.attributedText = NSAttributedString(
            string: "This app is for demo purposes only.".uppercased(),
            attributes: [
                .font: Fonts.footnote,
                .foregroundColor: Colors.primaryText,
                .kern: 0.2,
        ])
        return label
    }
}

// MARK: - Navigation

extension UIViewController {
    var sharedRouter: BankAppRouter {
        return (UIApplication.shared.delegate! as! AppDelegate).router
    }
}

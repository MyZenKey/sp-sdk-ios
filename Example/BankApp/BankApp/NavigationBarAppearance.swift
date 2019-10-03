//
//  NavigationBarAppearance.swift
//  BankApp
//
//  Created by Adam Tierney on 10/2/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

enum NavigationBarAppearance {
    static func configureNavBar() {
        UINavigationBar.appearance().titleTextAttributes = [
            .font: Fonts.lightHeadline,
            .foregroundColor: Colors.heavyText.value,
            .kern: -0.41,
        ]

        UINavigationBar.appearance().tintColor = Colors.heavyText.value

        UINavigationBar.appearance().backIndicatorImage = UIImage(named: "back-arrow")
    }
}

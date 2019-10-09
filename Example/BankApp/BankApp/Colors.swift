//
//  Colors.swift
//  BankApp
//
//  Created by Adam Tierney on 9/30/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

enum Colors: String {
    case fieldBackground
    case splashScreenBackground

    case brightAccent
    case lightAccent
    case mediumAccent

    case primaryText
    case secondaryText
    case heavyText
    case shadow
    case white
    case overlayWhite

    case gradientMax
    case gradientMid
    case brownGrey

    case transShadow

    var value: UIColor {
        guard let color = UIColor(named: self.rawValue) else {
            fatalError("color \(self) missing - configure it in the asset catalogue")
        }

        return color
    }
}

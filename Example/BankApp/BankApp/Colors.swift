//
//  Colors.swift
//  BankApp
//
//  Created by Adam Tierney on 9/30/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import UIKit

enum Colors: String {
    case fieldBackground

    case brightAccent
    case lightAccent

    case primaryText
    case secondaryText
    case heavyText

    case white

    var value: UIColor {
        guard let color = UIColor(named: self.rawValue) else {
            fatalError("color \(self) missing - configure it in the asset catalogue")
        }

        return color
    }
}
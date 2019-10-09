//
//  Colors.swift
//  BankApp
//
//  Created by Adam Tierney on 9/30/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

enum Colors {

    static let fieldBackground = ColorAssets.fieldBackground.color
    static let splashScreenBackground = ColorAssets.brand.color

    static let brightAccent = ColorAssets.brand.color
    static let lightAccent = ColorAssets.lightAccent.color
    static let mediumAccent = ColorAssets.mediumAccent.color

    static let heavyText = ColorAssets.primaryTint.color
    static let primaryText = ColorAssets.primaryText.color
    static let secondaryText = ColorAssets.secondaryText.color

    // Gradient Values
    static let white = ColorAssets.primaryBackground.color
    static let overlayWhite = ColorAssets.primaryBackground.color

    static let transShadow =  ColorAssets.transShadow.color

    static let gradientMax = ColorAssets.gradientMax.color
    static let gradientMid = ColorAssets.gradientMid.color
    static let brownGrey = ColorAssets.brownGrey.color

    static let shadow = ColorAssets.primaryTint.color
}

private enum ColorAssets: String {
    case fieldBackground

    case primaryText
    case secondaryText

    case heavyText
    case shadow
    case white
    case overlayWhite

    case lightAccent
    case mediumAccent

    case transShadow

    case gradientMax
    case gradientMid
    case brownGrey

    case brand
    case primaryTint
    case primaryBackground

    var color: UIColor {
        guard let color = UIColor(named: self.rawValue) else {
            fatalError("color \(self) missing - configure it in the asset catalogue")
        }
        return color
    }
}

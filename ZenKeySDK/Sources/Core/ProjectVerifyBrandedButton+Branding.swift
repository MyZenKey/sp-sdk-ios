//
//  ProjectVerifyBrandedButton+Branding.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 4/10/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

extension ProjectVerifyBrandedButton.Appearance {
    static let dark = ProjectVerifyBrandedButton.Appearance(
        normal: ColorScheme(
            title: .buttonWhite,
            image: .buttonWhite,
            background: .buttonGreen
        ),
        highlighted: ColorScheme(
            title: .buttonDimGray,
            image: .buttonDimGray,
            background: .buttonDimGreen
        )
    )

    static let light = ProjectVerifyBrandedButton.Appearance(
        normal: ColorScheme(
            title: .buttonGray,
            image: .buttonGreen,
            background: .buttonWhite
        ),
        highlighted: ColorScheme(
            title: .buttonDimGray,
            image: .buttonDimGray,
            background: .buttonDimLightGray
        )
    )
}

extension ProjectVerifyBrandedButton {
    var appearance: Appearance {
        switch style {
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }
}

private extension UIColor {
    static let buttonWhite = UIColor.white
    static let buttonGreen = UIColor(red: 46/255, green: 173/255, blue: 69/255, alpha: 1)
    static let buttonDimGreen = UIColor(red: 46/255, green: 173/255, blue: 69/255, alpha: 0.5)
    static let buttonGray = UIColor(red: 68/255, green: 68/255, blue: 68/255, alpha: 1)
    static let buttonDimGray = UIColor(red: 68/255, green: 68/255, blue: 68/255, alpha: 0.5)
    static let buttonDimLightGray = UIColor(red: 68/255, green: 68/255, blue: 68/255, alpha: 0.2)
}

//
//  ZenKeyBrandedButton+Branding.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 4/10/19.
//  Copyright © 2019 XCI JV, LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

extension ZenKeyBrandedButton.Appearance {
    static let dark = ZenKeyBrandedButton.Appearance(
        normal: ColorScheme(
            title: UIColor.Button.white,
            image: UIColor.Button.white,
            background: UIColor.Button.green
        ),
        highlighted: ColorScheme(
            title: UIColor.Button.darkGray,
            image: UIColor.Button.darkGray,
            background: UIColor.Button.lightGray
        )
    )

    static let light = ZenKeyBrandedButton.Appearance(
        normal: ColorScheme(
            title: UIColor.Button.black,
            image: UIColor.Button.green,
            background: UIColor.Button.white
        ),
        highlighted: ColorScheme(
            title: UIColor.Button.darkGray,
            image: UIColor.Button.darkGray,
            background: UIColor.Button.lightGray
        )
    )
}

extension ZenKeyBrandedButton {
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
    struct Button {
        static let black: UIColor = .black
        static let white: UIColor = .white
        static let green: UIColor = UIColor(red: 0, green: 133/255, blue: 34/255, alpha: 1)
        static let darkGray: UIColor = UIColor(red: 141/255, green: 141/255, blue: 141/255, alpha: 1)
        static let lightGray: UIColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
    }
}

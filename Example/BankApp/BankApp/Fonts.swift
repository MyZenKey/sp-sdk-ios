//
//  Fonts.swift
//  BankApp
//
//  Created by Adam Tierney on 9/30/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

enum Fonts {

    static let textField = UIFont.systemFont(ofSize: 13.0)
    static let accesory = UIFont.systemFont(ofSize: 13.0, weight: .medium)
    static let footnote = UIFont.systemFont(ofSize: 10.0, weight: .medium)
    static let cardSection = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
    static let largeTitle = UIFont.systemFont(ofSize: 42.0, weight: .thin)
    static let heavyText = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
    static let primaryText = UIFont.systemFont(ofSize: 13.0, weight: .regular)
}

extension Fonts {

    static func accessoryText(text: String, withColor color: UIColor) -> NSAttributedString {
        return NSAttributedString(
            string: text,
            attributes: [
                .font: Fonts.accesory,
                .foregroundColor: color,
                .kern: 0.2
            ])
    }
}

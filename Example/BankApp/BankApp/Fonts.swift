//
//  Fonts.swift
//  BankApp
//
//  Created by Adam Tierney on 9/30/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

enum Fonts {
    static let headline = UIFont.systemFont(ofSize: 17.0, weight: .bold)

    static let regularHeadline = UIFont.systemFont(ofSize: 17.0, weight: .regular)

    static let lightHeadline = UIFont.systemFont(ofSize: 17.0, weight: .semibold)

    static let mediumCallout = UIFont.systemFont(ofSize: 15.0, weight: .medium)

    static let textField = UIFont.systemFont(ofSize: 13.0)
    static let accesory = UIFont.systemFont(ofSize: 13.0, weight: .medium)

    static let mediumAccesory = UIFont.systemFont(ofSize: 13.0, weight: .medium)

    static let regularAccesory = UIFont.systemFont(ofSize: 13.0, weight: .regular)

    static let footnote = UIFont.systemFont(ofSize: 10.0, weight: .medium)
    static let cardSection = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
    static let largeTitle = UIFont.systemFont(ofSize: 42.0, weight: .thin)
    static let heavyText = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
    static let primaryText = UIFont.systemFont(ofSize: 13.0, weight: .regular)
}

extension Fonts {

    static func boldHeadlineText(text: String, withColor color: UIColor) -> NSAttributedString {
        return NSAttributedString(
            string: text,
            attributes: [
                .font: Fonts.headline,
                .foregroundColor: color,
                .kern: 0.03
            ])
    }

    static func regularHeadlineText(text: String, withColor color: UIColor) -> NSAttributedString {
        return NSAttributedString(
            string: text,
            attributes: [
                .font: Fonts.regularHeadline,
                .foregroundColor: color,
                .kern: 0.03
            ])
    }

    static func mediumAccessoryText(text: String, withColor color: UIColor) -> NSAttributedString {
        return NSAttributedString(
            string: text,
            attributes: [
                .font: Fonts.mediumAccesory,
                .foregroundColor: color,
                .kern: 0.2
            ])
    }

    static func regularAccessoryText(text: String, withColor color: UIColor) -> NSAttributedString {
        return NSAttributedString(
            string: text,
            attributes: [
                .font: Fonts.regularAccesory,
                .foregroundColor: color,
                .kern: 0.2
            ])
    }

    static func mediumCalloutText(text: String, withColor color: UIColor) -> NSAttributedString {
        return NSAttributedString(
            string: text,
            attributes: [
                .font: Fonts.mediumCallout,
                .foregroundColor: color,
                .kern: 0.2
            ])
    }
}

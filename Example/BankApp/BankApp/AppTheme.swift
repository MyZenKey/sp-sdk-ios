//
//  AppTheme.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL
// MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING
// AGREEMENT DATED FEBRUARY 7, 2018.
//

import Foundation
import UIKit

struct AppTheme {
    static let primaryBlue = UIColor(hexString: "0BB3D7")
    static let gradientTopColor = UIColor(hexString: "518EF5")
    static let gradientBottomColor = UIColor(hexString: "0BB3D7")
}

extension UIColor {
    convenience init(hexString: String) {
        let hexStringCleaned = hexString.trimmingCharacters(in: NSCharacterSet.alphanumerics.inverted)
        var hexIntValue: UInt32 = 0
        let scanner = Scanner(string: hexStringCleaned)
        scanner.scanHexInt32(&hexIntValue)
        let a, r, g, b: UInt32
        switch hexStringCleaned.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (hexIntValue >> 8) * 17, (hexIntValue >> 4 & 0xF) * 17, (hexIntValue & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, hexIntValue >> 16, hexIntValue >> 8 & 0xFF, hexIntValue & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (hexIntValue >> 24, hexIntValue >> 16 & 0xFF, hexIntValue >> 8 & 0xFF, hexIntValue & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

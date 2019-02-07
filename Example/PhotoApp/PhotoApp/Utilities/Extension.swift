//
//  Extension.swift
//  PhotoApp
//
//  Created by Sawyer Billings on 2/6/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import Foundation
import UIKit

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

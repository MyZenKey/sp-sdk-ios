//
//  Extensions.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED AUGUST 24, 2018.
//

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

extension UIViewController {
    func updateNavigationThemeColor() {
        let layer = CAGradientLayer()
        var navBarFrame = self.navigationController!.navigationBar.bounds;
        navBarFrame.size.height += UIApplication.shared.statusBarFrame.size.height;
        layer.frame = navBarFrame
        layer.colors = [UIColor.init(red: 204/255.0, green: 128/255.0, blue: 243/255.0, alpha: 1.0).cgColor, UIColor.init(red: 74/255.0, green: 144/255.0, blue: 226/255.0, alpha: 1.0).cgColor]
        self.navigationController!.navigationBar.setBackgroundImage(imageFromLayer(layer: layer), for: UIBarMetrics.default)
    }
    
    func imageFromLayer (layer : CALayer) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, UIScreen.main.scale)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return outputImage!
    }
}

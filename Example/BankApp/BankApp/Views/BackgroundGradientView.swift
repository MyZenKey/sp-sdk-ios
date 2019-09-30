//
//  BackgroundGradientView.swift
//  BankApp
//
//  Created by Isaak Meier on 9/30/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import UIKit
import Foundation

class BackgroundGradientView: UIView {

    @IBInspectable var startColor: CGColor = UIColor(red: 255/255.0, green: 255/255.05, blue: 255/255.0, alpha: 1).cgColor
    @IBInspectable var middleColor: CGColor = UIColor(red: 253/255.0, green: 253/255.0, blue: 253/255.0, alpha: 1).cgColor
    @IBInspectable var endColor: CGColor = UIColor(red: 213/255.0, green: 213/255.0, blue: 213/255.0, alpha: 1).cgColor

    override class var layerClass: AnyClass { return CAGradientLayer.self }
    var gradientLayer: CAGradientLayer { return layer as! CAGradientLayer }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.colors = [startColor, middleColor, endColor]
        gradientLayer.locations = [0, 0.45, 1]
    }

}

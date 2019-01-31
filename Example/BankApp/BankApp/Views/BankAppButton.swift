//
//  BankAppButton.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

@IBDesignable
class BankAppButton: UIButton {

    @IBInspectable var cornerRadius: CGFloat = 5 {
        didSet(newValue) {
            setNeedsDisplay()
        }
    }

    @IBInspectable var borderColor: UIColor = AppTheme.buttonColor {
        didSet(newValue) {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet(newValue) {
            setNeedsDisplay()
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        myInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        myInit()
    }

    private func myInit() {
        
        imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
    }
    
    func updateLayer() {
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
        layer.masksToBounds = false
        layer.rasterizationScale = UIScreen.main.scale
        layer.shouldRasterize = true
        layer.cornerRadius = cornerRadius
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayer()
    }
}

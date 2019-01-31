//
//  DotView.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

@IBDesignable
class DotView: UIView {

    @IBInspectable var empty: Bool = true {
        didSet(newValue) {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var color: UIColor = .black {
        didSet(newValue) {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var thickness: CGFloat = 2 {
        didSet(newValue) {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(ovalIn: rect)
        color.setFill()
        path.fill()
        if empty {
            let innerRect = CGRect(x: rect.origin.x + thickness, y: rect.origin.y + thickness, width: rect.width - thickness*2, height: rect.height - thickness*2)
            let innerPath = UIBezierPath(ovalIn: innerRect)
//            if color == UIColor.white {
//                VerifyTheme.colorVerifyGreen.setFill()
//            } else {
                UIColor.white.setFill()
//            }
            innerPath.fill()
        }
    }

}

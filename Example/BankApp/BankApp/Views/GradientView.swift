//
//  GradientView.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

@IBDesignable
class GradientView: UIView {
    
    @IBInspectable var startColor:   UIColor = AppTheme.gradientTopColor { didSet { updateColors() }}
    @IBInspectable var midColor:   UIColor = AppTheme.gradientTopColor { didSet { updateColors() }}
    @IBInspectable var endColor:     UIColor = AppTheme.gradientBottomColor { didSet { updateColors() }}
    @IBInspectable var startLocation: Double =   0.05 { didSet { updateLocations() }}
    @IBInspectable var midLocation: Double =   0.5 { didSet { updateLocations() }}
    @IBInspectable var endLocation:   Double =   0.95 { didSet { updateLocations() }}
    @IBInspectable var horizontalMode:  Bool =  false { didSet { updatePoints() }}
    @IBInspectable var diagonalMode:    Bool =  false { didSet { updatePoints() }}
    @IBInspectable var midPointMode:    Bool =  false { didSet { updateLocations(); updateColors() }}


    // Trick to make the CALayer be the CAGradientLayer which you control (returns the class)
    override class var layerClass: AnyClass { return CAGradientLayer.self }

    // In order to access, you have to force cast, so this is a convenience getter
    var gradientLayer: CAGradientLayer { return layer as! CAGradientLayer }

    func updatePoints() {
        if horizontalMode {
            gradientLayer.startPoint = diagonalMode ? CGPoint(x: 1, y: 0) : CGPoint(x: 0, y: 0.5)
            gradientLayer.endPoint   = diagonalMode ? CGPoint(x: 0, y: 1) : CGPoint(x: 1, y: 0.5)
        } else {
            gradientLayer.startPoint = diagonalMode ? CGPoint(x: 0, y: 0) : CGPoint(x: 0.5, y: 0)
            gradientLayer.endPoint   = diagonalMode ? CGPoint(x: 1, y: 1) : CGPoint(x: 0.5, y: 1)
        }
    }

    func updateLocations() {
        if midPointMode {
            gradientLayer.locations = [startLocation as NSNumber, midLocation as NSNumber, endLocation as NSNumber]
        } else {
            gradientLayer.locations = [startLocation as NSNumber, endLocation as NSNumber]
        }
    }

    func updateColors() {
        if midPointMode {
            gradientLayer.colors = [startColor.cgColor, midColor.cgColor, endColor.cgColor]
        } else {
            gradientLayer.colors    = [startColor.cgColor, endColor.cgColor]
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        updatePoints()
        updateLocations()
        updateColors()
    }
}


class LogoGradientView: GradientView {
    let logo: UIImageView = {
        let logo = UIImageView()
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.image = UIImage(named: "applogo_white")
        logo.contentMode = .scaleAspectFit
        return logo
    }()

    let leadingButtonAreaLayoutGuide: UILayoutGuide = {
        let guide = UILayoutGuide()
        guide.identifier = "leading button area layout guide"
        return guide
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    func sharedInit() {

        if (bounds.isEmpty) {
            sizeToFit()
        }

        addSubview(logo)
        addLayoutGuide(leadingButtonAreaLayoutGuide)

        let yAdjustment: CGFloat
        if #available(iOS 11.0, *) {
            yAdjustment = 0
        } else {
            yAdjustment = UIApplication.shared.statusBarFrame.height
        }

        addConstraints([
            logo.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor),
            logo.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor,
                                          constant: yAdjustment / 2),

            leadingButtonAreaLayoutGuide.leadingAnchor.constraint(equalTo: leadingAnchor),
            leadingButtonAreaLayoutGuide.trailingAnchor.constraint(equalTo: logo.leadingAnchor),
            leadingButtonAreaLayoutGuide.topAnchor.constraint(equalTo: logo.topAnchor),
            leadingButtonAreaLayoutGuide.bottomAnchor.constraint(equalTo: logo.bottomAnchor),
        ])
    }
}

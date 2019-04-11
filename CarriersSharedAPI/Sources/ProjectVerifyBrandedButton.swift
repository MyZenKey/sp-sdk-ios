//
//  ProjectVerifyBrandedButton.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 4/10/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

public class ProjectVerifyBrandedButton: UIButton {
    public override var isHighlighted: Bool {
        didSet {
            updateTinting()
        }
    }
    
    public override var isEnabled: Bool {
        didSet {
            updateTinting()
        }
    }
    
    /// A style for the button to adopt. Light backgrounds should prefer a dark style, while
    /// dark backgrounds may find a light style provides greater contrast.
    ///
    /// - SeeAlso: `ProjectVerifyBrandedButton.Style`
    public var style: Style = .dark
    
    var branding: Branding = .default {
        didSet {
            updateBranding()
        }
    }
    
    let configCacheService: ConfigCacheServiceProtocol = Dependencies.resolve()
    let carrierInfoService: CarrierInfoServiceProtocol = Dependencies.resolve()
    
    public init() {
        super.init(frame: .zero)
        configureButton()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureButton()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureButton()
    }
}

// MARK: - sub-types

extension ProjectVerifyBrandedButton {
    enum Branding {
        case `default`
    }
    
    /// Provide guidance for the button to use a light background button or a dark background button.
    public enum Style {
        /// Suggests the button should prefer using a light background
        case light
        /// Suggests the button should prefer using a dark background
        case dark
    }
    
    /// Branded button appearance configuration
    struct Appearance {
        struct ColorScheme {
            let normal: UIColor
            let highlighted: UIColor
        }
        
        let title: ColorScheme
        let image: ColorScheme
        let background: ColorScheme
    }
}

// MARK: - private config

private extension ProjectVerifyBrandedButton {
    func configureButton() {
        branding = brandingFromCache()
    }
    
    func updateBranding() {
        adjustsImageWhenHighlighted = false
        
        layer.cornerRadius = Constants.cornerRadius
        
        titleEdgeInsets = .projectVerifyButtonTitleEdgeInsets
        imageEdgeInsets = .projectVerifyButtonImageEdgeInsets
        
        setAttributedTitle(
            attributedTitle(
                forTitle: branding.primaryText,
                withColor: appearance.title.normal
            ),
            for: .normal
        )
        
        setAttributedTitle(
            attributedTitle(
                forTitle: branding.primaryText,
                withColor: appearance.title.highlighted
            ),
            for: .highlighted
        )
        
        setImage(branding.icon, for: .normal)
        
        updateTinting()
    }
    
    func updateTinting() {
        if isHighlighted || !isEnabled {
            tintColor = appearance.image.highlighted
            backgroundColor = appearance.background.highlighted
        } else {
            tintColor = appearance.image.normal
            backgroundColor = appearance.background.normal
        }
    }
    
    func attributedTitle(forTitle title: String,
                         withColor color: UIColor) -> NSAttributedString {
        let attributes: [NSAttributedString.Key : Any] = [
            .foregroundColor: color,
            .font: UIFont.boldSystemFont(ofSize: 17.0),
        ]
        let attributedString = NSAttributedString(string: title, attributes: attributes)
        return attributedString
    }
}


// MARK: - Geometery exetensions

private extension ProjectVerifyBrandedButton {
    enum Constants {
        static let cornerRadius: CGFloat = 8
        static let height: CGFloat = 52
    }
}

private extension UIEdgeInsets {
    static let offset: CGFloat = 5
    
    static var projectVerifyButtonTitleEdgeInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: offset, bottom: 0, right: -offset)
    }
    
    static var projectVerifyButtonImageEdgeInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: -offset, bottom: 0, right: offset)
    }
}

private extension CGSize {
    static var projectVerifyButtonSize: CGSize {
        return CGSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: ProjectVerifyBrandedButton.Constants.height
        )
    }
}

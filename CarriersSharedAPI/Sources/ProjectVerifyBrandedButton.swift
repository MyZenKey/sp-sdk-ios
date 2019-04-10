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
            updateBackgroundColor()
        }
    }
    
    ///
    public var uiHint: UIHint = .dark
    
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
    
    private func configureButton() {
        branding = brandingFromCache()
    }
    
    private func updateBranding() {
        
        layer.cornerRadius = Constants.cornerRadius
        
        setTitleColor(colorScheme.foreground, for: .normal)
        setTitle(branding.primaryText, for: .normal)
        
        setAttributedTitle(
            attributedTitle(forTitle: branding.primaryText),
            for: .normal
        )
        
        setImage(branding.icon(forUI: uiHint), for: .normal)
        
        titleEdgeInsets = .projectVerifyButtonTitleEdgeInsets
        imageEdgeInsets = .projectVerifyButtonImageEdgeInsets
        
        updateBackgroundColor()
    }
    
    private func updateBackgroundColor() {
        backgroundColor = isHighlighted ?
            colorScheme.highlight : colorScheme.background
    }
    
    private func attributedTitle(forTitle title: String) -> NSAttributedString {
        let attributes: [NSAttributedString.Key : Any] = [
            .foregroundColor: colorScheme.foreground,
            .font: UIFont.boldSystemFont(ofSize: 17.0),
        ]
        let attributedString = NSAttributedString(string: title, attributes: attributes)
        return attributedString
    }
}

extension ProjectVerifyBrandedButton {
    enum Branding {
        case `default`
    }
    
    /// Provide guidance for the button to use a light background button or a dark background button.
    public enum UIHint {
        /// Suggests the button should prefer using a light background
        case light
        /// Suggests the button should prefer using a dark background
        case dark
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

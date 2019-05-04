//
//  ProjectVerifyBrandedButton.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 4/10/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

/// A branded ProjectVerifyButton
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
    public var style: Style = .dark {
        didSet {
            updateBranding()
        }
    }
    
    var branding: Branding = .default {
        didSet {
            updateBranding()
        }
    }
    
    // NOTE: dependencies are resolved automatically for all of the button initalizers.
    // can use the custom initializer `init(configCacheService:carrierInfoService:)` to pass
    // specific dependencies.
    
    let configCacheService: ConfigCacheServiceProtocol
    let carrierInfoService: CarrierInfoServiceProtocol
    
    public init() {
        configCacheService = ProjectVerifyAppDelegate.shared.dependencies.resolve()
        carrierInfoService = ProjectVerifyAppDelegate.shared.dependencies.resolve()
        super.init(frame: .zero)
        configureButton()
    }
    
    init(dependencyContainer container: Dependencies = ProjectVerifyAppDelegate.shared.dependencies) {
        self.configCacheService = container.resolve()
        self.carrierInfoService = container.resolve()
        super.init(frame: .zero)
        configureButton()
    }

    init(configCacheService: ConfigCacheServiceProtocol,
         carrierInfoService: CarrierInfoServiceProtocol) {
        self.configCacheService = configCacheService
        self.carrierInfoService = carrierInfoService
        super.init(frame: .zero)
        configureButton()
    }

    public override init(frame: CGRect) {
        configCacheService = ProjectVerifyAppDelegate.shared.dependencies.resolve()
        carrierInfoService = ProjectVerifyAppDelegate.shared.dependencies.resolve()
        super.init(frame: frame)
        configureButton()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        configCacheService = ProjectVerifyAppDelegate.shared.dependencies.resolve()
        carrierInfoService = ProjectVerifyAppDelegate.shared.dependencies.resolve()
        super.init(coder: aDecoder)
        configureButton()
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        configureButton()
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard !isHidden else { return .zero }
        
        let fittingSize = super.sizeThatFits(size)
        return CGSize(width: max(fittingSize.width, size.width), height: Constants.height)
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
            let title: UIColor
            let image: UIColor
            let background: UIColor
        }
        
        let normal: ColorScheme
        let highlighted: ColorScheme
    }
}

// MARK: - private config

private extension ProjectVerifyBrandedButton {
    func configureButton() {
        
        adjustsImageWhenHighlighted = false
        adjustsImageWhenDisabled = false
        
        layer.cornerRadius = Constants.cornerRadius

        contentEdgeInsets = .projectVerifyButtonContentInsets
        titleEdgeInsets = .projectVerifyButtonTitleEdgeInsets
        imageEdgeInsets = .projectVerifyButtonImageEdgeInsets

        branding = brandingFromCache()
        
        if bounds.isEmpty {
            sizeToFit()
        }
    }
    
    func updateBranding() {
        setAttributedTitle(
            attributedTitle(
                forTitle: branding.primaryText,
                withColor: appearance.normal.title
            ),
            for: .normal
        )
        
        setAttributedTitle(
            attributedTitle(
                forTitle: branding.primaryText,
                withColor: appearance.highlighted.title
            ),
            for: .highlighted
        )
        
        setAttributedTitle(
            attributedTitle(
                forTitle: branding.primaryText,
                withColor: appearance.highlighted.title
            ),
            for: .disabled
        )
        
        setImage(branding.icon, for: .normal)
        
        updateTinting()
    }
    
    func updateTinting() {
        let colorScheme: Appearance.ColorScheme
        if isHighlighted || !isEnabled {
            colorScheme = appearance.highlighted
        } else {
            colorScheme = appearance.normal
        }
        
        tintColor = colorScheme.image
        backgroundColor = colorScheme.background

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
    static let xOffset: CGFloat = 5
    
    static var projectVerifyButtonContentInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 42, bottom: 16, right: 42)
    }
    
    static var projectVerifyButtonTitleEdgeInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: xOffset, bottom: 0, right: -xOffset)
    }
    
    static var projectVerifyButtonImageEdgeInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: -xOffset, bottom: 0, right: xOffset)
    }
}

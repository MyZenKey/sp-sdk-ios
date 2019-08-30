//
//  ZenKeyBrandedButton.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 4/10/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

/// A protocol which represents the interface for handling changes to branding information.
///
/// Implement this protocol and specify the `brandingDelegate` on a ZenKeyBrandedButton to
/// recieve changes to the button's branding information.
public protocol ZenKeyBrandedButtonDelegate: AnyObject {
    /// Called before the button updates its branding with the previous branding value
    ///
    /// - Parameters:
    ///   - oldBranding: the old branding of the button
    ///   - button: the button instance
    func brandingWillUpdate(_ oldBranding: Branding, forButton button: ZenKeyBrandedButton)

    /// Called after the button updates its branding with the new branding value
    ///
    /// - Parameters:
    ///   - newBranding: the new branding of the button
    ///   - button: the button instance
    func brandingDidUpdate(_ newBranding: Branding, forButton button: ZenKeyBrandedButton)
}

/// A branded ZenKeyButton
public class ZenKeyBrandedButton: UIButton {

    /// the button's brandding delegate
    /// - SeeAlso: ZenKeyBrandedButtonDelegate
    public weak var brandingDelegate: ZenKeyBrandedButtonDelegate?

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
    /// - SeeAlso: `ZenKeyBrandedButton.Style`
    public var style: Style = .dark {
        didSet {
            updateBrandingPresentation()
        }
    }

    var branding: Branding = .default {
        didSet {
            brandingDelegate?.brandingWillUpdate(oldValue, forButton: self)
            updateBrandingPresentation()
            invalidateIntrinsicContentSize()
            brandingDelegate?.brandingDidUpdate(branding, forButton: self)
        }
    }

    override public var intrinsicContentSize: CGSize {
        return sizeThatFits(.zero)
    }

    // NOTE: dependencies are resolved automatically for all of the button initalizers.
    // can use the custom initializer `init(configCacheService:carrierInfoService:)` to pass
    // specific dependencies.

    let brandingProvider: BrandingProvider

    public init() {
        brandingProvider = ZenKeyAppDelegate.shared.dependencies.resolve()
        super.init(frame: .zero)
        configureButton()
    }

    init(dependencyContainer container: Dependencies = ZenKeyAppDelegate.shared.dependencies) {
        brandingProvider = container.resolve()
        super.init(frame: .zero)
        configureButton()
    }

    init(brandingProvider: BrandingProvider) {
        self.brandingProvider = brandingProvider
        super.init(frame: .zero)
        configureButton()
    }

    public override init(frame: CGRect) {
        brandingProvider = ZenKeyAppDelegate.shared.dependencies.resolve()
        super.init(frame: frame)
        configureButton()
    }

    public required init?(coder aDecoder: NSCoder) {
        brandingProvider = ZenKeyAppDelegate.shared.dependencies.resolve()
        super.init(coder: aDecoder)
        configureButton()
    }

    public override func awakeFromNib() {
        super.awakeFromNib()
        configureButton()
    }

    private var spaceTitleAndImageRects: Bool {
        if attributedTitle(for: state) != nil && branding.icon != nil {
            return true
        } else {
            return false
        }
    }

    private func trueContentSize() -> CGSize {
        let titleSize: CGSize = measuredTitleSize

        let iconSize = measuredImageSize

        let contentWidth =
            iconSize.width +
            titleSize.width +
            CGFloat(spaceTitleAndImageRects ? Constants.interitemSpacing : 0.0)

        return CGSize(width: contentWidth, height: max(titleSize.height, iconSize.height))
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard !isHidden else { return .zero }
        let contentSize = trueContentSize()
        return CGSize(
            width: contentSize.width + (2 * Insets.horizontal),
            height: contentSize.height + (2 * Insets.vertical)
        )
    }

    public override func contentRect(forBounds bounds: CGRect) -> CGRect {
        guard !bounds.isEmpty else {
            return .zero
        }

        guard
            bounds.size.width >= 2 * Insets.Minimum.horizontal,
            bounds.size.height >= 2 * Insets.Minimum.vertical else {
                return .zero
        }

        // try to fit the content rect into the button size – if it doesn't fit shrink down to
        // minimum margins at most.
        let boundsSize = bounds.size
        let contentSize = trueContentSize()

        let widthDelta = boundsSize.width - contentSize.width
        let heightDelta = boundsSize.height - contentSize.height

        // if negative, apply bounded to minimum insets, else use the marigns:
        let widthModifier = widthDelta >= 0 ? 0 : widthDelta
        let heightModifier = heightDelta >= 0 ? 0 : heightDelta
        let fitMargins = CGSize(
            width: max( (Insets.horizontal * 2) + widthModifier, Insets.Minimum.horizontal * 2 ),
            height: max( (Insets.vertical * 2) + heightModifier, Insets.Minimum.vertical * 2 )
        )

        return CGRect(x: fitMargins.width / 2,
                      y: fitMargins.height / 2,
                      width: bounds.size.width - fitMargins.width,
                      height: bounds.size.height - fitMargins.height
        )
    }

    public override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        guard !contentRect.isEmpty else {
            return .zero
        }

        // #NTH: - potentially add title scaling behavior to support smaller buttons:
        let imageRect = self.imageRect(forContentRect: contentRect)
        let offset: CGFloat = spaceTitleAndImageRects ? Constants.interitemSpacing : 0

        // x axis: attempt to center the label in the content rect provided,
        // min x must be >= image + interitem spacing, max x must be <= right margin
        // y axis: use content rect
        let titleSize = measuredTitleSize
        let boundedTextRectCenteredInButton = CGRect(
            x: contentRect.minX + max((contentRect.width - titleSize.width), 1) / 2,
            y: contentRect.minY + max((contentRect.height - titleSize.height), 1) / 2,
            width: min(titleSize.width, contentRect.width),
            height: min(titleSize.height, contentRect.width)
        )

        let imageRectPlusInteritem = imageRect.maxX + offset

        // 1) if the centered text fits in space between far right margin & image + spacer,
        //    then use the centered frame.
        // 2) if text won't fit in that space, left justify and grow from there.
        let xOrigin: CGFloat
        if boundedTextRectCenteredInButton.width >= titleSize.width &&
            boundedTextRectCenteredInButton.minX >= imageRectPlusInteritem {
            xOrigin = boundedTextRectCenteredInButton.origin.x
        } else {
            // NOTE: we could also grow from the right:
            // ie: contentRect.maxX - boundedTextRectCenteredInButton.size.width
            // or attempt to center this rect bewteen the imageRectPlusInteritem & right margin
            xOrigin = imageRectPlusInteritem
        }

        return CGRect(
            x: xOrigin,
            y: contentRect.minY,
            width: min( boundedTextRectCenteredInButton.size.width, contentRect.maxX - xOrigin ),
            height: contentRect.height
        )
    }

    public override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let imageSize = measuredImageSize

        guard imageSize.width != 0, imageSize.height != 0 else {
            return .zero
        }

        // preserve aspect ratio if scaled down
        // constraining axis is delta with greater abs:
        let deltaX = contentRect.size.width - imageSize.width
        let deltaY = contentRect.size.height - imageSize.height

        // use image size if it will fit
        guard deltaX <= 0 || deltaY <= 0 else {
            return CGRect(
                x: contentRect.minX,
                y: contentRect.midY - imageSize.height / 2,
                width: imageSize.width,
                height: imageSize.height
            )
        }

        let aspectRatio = imageSize.width / imageSize.height
        let width: CGFloat
        let height: CGFloat
        if deltaX < deltaY {
            // constrained on width
            width = imageSize.width + deltaX
            height = width / aspectRatio
        } else {
            // constrined on height
            height = imageSize.height + deltaY
            width = height * aspectRatio
        }

        return CGRect(
            x: contentRect.minX,
            y: contentRect.midY - height / 2,
            width: width,
            height: height
        )
    }
}

public extension ZenKeyBrandedButton {
    /// Prefer this method for updating the text of the BrandedButton. This method implemnts an
    /// expected, branded behavior for multiple control states by applying the branded attributes
    /// to the provided string.
    ///
    /// - Parameter text: The text for the button's title label.
    func updateBrandedText(_ text: String) {
        setAttributedTitle(
            attributedTitle(
                forTitle: text,
                withColor: appearance.normal.title
            ),
            for: .normal
        )

        setAttributedTitle(
            attributedTitle(
                forTitle: text,
                withColor: appearance.highlighted.title
            ),
            for: .highlighted
        )

        setAttributedTitle(
            attributedTitle(
                forTitle: text,
                withColor: appearance.highlighted.title
            ),
            for: .disabled
        )

        invalidateIntrinsicContentSize()
    }
}

// MARK: - sub-types

extension ZenKeyBrandedButton {
    /// Provide guidance for the button to use a light background button or a dark background button.
    public enum Style {
        /// Suggests the button should prefer using a light background
        case light
        /// Suggests the button should prefer using a dark background
        case dark
    }

    /// Branded button appearance configuration
    struct Appearance {
        // swiftlint:disable:next nesting
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

private extension ZenKeyBrandedButton {

    var measuredImageSize: CGSize {
        return branding.icon?.size ?? .zero
    }

    var measuredTitleSize: CGSize {
        let greatestSize = CGSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        return attributedTitle(for: state)?
            .boundingRect(
                with: greatestSize,
                options: [.usesFontLeading, .usesLineFragmentOrigin],
                context: nil
            ).size ?? .zero
    }

    func configureButton() {
        adjustsImageWhenHighlighted = false
        adjustsImageWhenDisabled = false

        layer.cornerRadius = Constants.cornerRadius

        layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 2
        layer.shadowOpacity = 0.24

        titleLabel?.lineBreakMode = .byTruncatingTail

        brandingProvider.brandingDidChange = { [weak self] branding in
            self?.branding = branding
        }

        branding = brandingProvider.buttonBranding

        if bounds.isEmpty {
            sizeToFit()
        }
    }

    func updateBrandingPresentation() {
        setImage(branding.icon, for: .normal)
        updateTinting()
        if let title = attributedTitle(for: .normal)?.string {
            updateBrandedText(title)
        }
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
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .kern: 0.22,
            .font: UIFont.boldSystemFont(ofSize: 14.0),
        ]
        let attributedString = NSAttributedString(string: title, attributes: attributes)
        return attributedString
    }
}

// MARK: - Geometery exetensions

private extension ZenKeyBrandedButton {
    enum Constants {
        static let cornerRadius: CGFloat = 2
        static let interitemSpacing: CGFloat = 25
    }

    enum Insets {
        static let vertical: CGFloat = 12
        static let horizontal: CGFloat = 24
        // swiftlint:disable:next nesting
        enum Minimum {
            static let vertical: CGFloat = 5
            static let horizontal: CGFloat = 15
        }
    }
}
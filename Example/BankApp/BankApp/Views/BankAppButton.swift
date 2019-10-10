//
//  BankAppButton.swift
//  BankApp
//
//  Created by Adam Tierney on 10/7/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

final class BankAppButton: UIButton {

    override var isHighlighted: Bool {
        didSet {
            updateTint()
        }
    }

    override var isEnabled: Bool {
        didSet {
            updateTint()
        }
    }

    var buttonTitle: String = "" {
        didSet {
            updateButton(withText: buttonTitle)
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.shadowColor = Colors.shadow.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 2
        layer.shadowOpacity = 0.24
    }
}

private extension BankAppButton {
    func sharedInit() {
        layer.cornerRadius = 2
        updateTint()
        updateButton(withText: buttonTitle)
    }

    func updateButton(withText: String) {

        let normalText = Fonts.semiboldHeadlineText(
            text: buttonTitle,
            withColor: Colors.white
        )

        setAttributedTitle(
            normalText,
            for: .normal
        )

        let highlightedText = Fonts.semiboldHeadlineText(
            text: buttonTitle,
            withColor: Colors.primaryText
        )

        setAttributedTitle(
            highlightedText,
            for: .highlighted
        )

        setAttributedTitle(
            highlightedText,
            for: .disabled
        )
    }

    func updateTint() {
        if isHighlighted || !isEnabled {
            backgroundColor = Colors.fieldBackground
        } else {
            backgroundColor = Colors.brightAccent
        }
    }
}

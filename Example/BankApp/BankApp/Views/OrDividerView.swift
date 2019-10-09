//
//  OrDividerView.swift
//  BankApp
//
//  Created by Adam Tierney on 9/30/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

final class OrDividerView: UIStackView {

    init() {
        super.init(frame: .zero)

        let hairlineOne = newHairline()
        let hairlineTwo = newHairline()

        addArrangedSubview(hairlineOne)
        addArrangedSubview(newOrLabel())
        addArrangedSubview(hairlineTwo)

        alignment = .center
        axis = .horizontal
        distribution = .fill
        spacing = 4

        NSLayoutConstraint.activate([
            hairlineOne.widthAnchor.constraint(equalTo: hairlineTwo.widthAnchor)
        ])
    }

    @available(*, unavailable)
    init(arrangedSubviews views: [UIView]) {
        fatalError("unavailable")
    }

    @available(*, unavailable)
    override init(frame: CGRect) {
        fatalError("unavailable")
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("unavailable")
    }

    private func newOrLabel() -> UILabel {
        let label = UILabel(frame: .zero)
        label.text = "or"
        label.font = Fonts.mediumAccesory
        label.textColor = Colors.secondaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        return label
    }

    private func newHairline() -> UIView {
        let hairline = UIView(frame: .zero)
        hairline.backgroundColor = Colors.secondaryText
        hairline.setContentHuggingPriority(.defaultLow, for: .horizontal)

        NSLayoutConstraint.activate([
            hairline.heightAnchor.constraint(equalToConstant: 1)
        ])

        return hairline
    }
}

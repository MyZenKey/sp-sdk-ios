//
//  AccountCard.swift
//  BankApp
//
//  Created by Chad on 10/9/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

class AccountCard: UIView {
    let backgroundImage: UIImageView

    let accountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Fonts.heavyText
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    let numberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Fonts.primaryText
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    let textContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    init(_ text: String, icon: UIImage) {
        self.backgroundImage = UIImageView(image: icon)
        super.init(frame: .zero)
        layout()
        accountLabel.text = text
        numberLabel.text = "– \(String(format: "%04d", Int.random(in: 0 ..< 10000)))"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layout() {
        backgroundColor = Colors.white
        addSubview(backgroundImage)
        addSubview(textContainer)
        textContainer.addSubview(accountLabel)
        textContainer.addSubview(numberLabel)
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundImage.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            backgroundImage.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            backgroundImage.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),

            textContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            textContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15.0),
            textContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15.0),

            accountLabel.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor),
            accountLabel.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor),
            accountLabel.topAnchor.constraint(equalTo: textContainer.topAnchor),

            numberLabel.topAnchor.constraint(equalTo: accountLabel.bottomAnchor, constant: 4.0),
            numberLabel.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor),
            numberLabel.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor),
            numberLabel.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor),

            ])
        addBankShadow()
    }
}

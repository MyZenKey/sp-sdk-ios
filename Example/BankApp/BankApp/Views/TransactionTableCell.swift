//
//  TransactionTableCell.swift
//  BankApp
//
//  Created by Adam Tierney on 10/7/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

final class TransactionTableCell: UITableViewCell {

    static let identifier = "TransactionTableCell"

    var circleText: String = "" {
        didSet {
            circleLabel.attributedText = Fonts.mediumCalloutText(
                text: circleText,
                withColor: Colors.white.value
            )
        }
    }

    var titleText: String = "" {
        didSet {
            titleLabel.attributedText = Fonts.boldHeadlineText(
                text: titleText,
                withColor: Colors.heavyText.value
            )
        }
    }

    var subtitleText: String = "" {
        didSet {
            subtitleLabel.attributedText = Fonts.regularHeadlineText(
                text: subtitleText,
                withColor: Colors.primaryText.value
            )
        }
    }

    var footerText: String = "" {
        didSet {
            footerLabel.attributedText = Fonts.regularAccessoryText(
                text: footerText,
                withColor: Colors.primaryText.value
            )
        }
    }

    var accessoryText: String = "" {
        didSet {
            accessoryLabel.attributedText = Fonts.boldHeadlineText(
                text: accessoryText,
                withColor: Colors.heavyText.value
            )
        }
    }

    private let circleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return label
    }()

    private lazy var circleView: CircleView = {
        let view = CircleView(frame: .zero)

        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Colors.brightAccent.value
        view.addSubview(circleLabel)

        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: Constants.circleDiameter),
            circleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            circleLabel.topAnchor.constraint(equalTo: view.topAnchor),
            circleLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            circleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            circleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        return label
    }()

    private let footerLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.66
        return label
    }()

    private let accessoryLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .right
        return label
    }()

    private(set) lazy var labelStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel,
            footerLabel,
        ])

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 1

        return stackView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            circleView,
            labelStack,
            accessoryLabel,
        ])

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = Constants.horizontalSpacing

        return stackView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension TransactionTableCell {

    enum Constants {
        static let circleDiameter: CGFloat = 48
        static let horizontalSpacing: CGFloat = 25
    }

    func sharedInit() {

        contentView.layoutMargins = UIEdgeInsets(top: 15, left: 0, bottom: 15, right: 0)

        contentView.addSubview(contentStackView)
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
        ])
    }
}

private final class CircleView: UIView {

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func sharedInit() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: heightAnchor),
            ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = ceil(frame.height / 2)
    }
}

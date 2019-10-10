//
//  UserCardView.swift
//  BankApp
//
//  Created by Chad on 10/9/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

class UserCardView: UIView {
    public var userInfo: UserInfo? {
        didSet {
            updateUserInfo()
        }
    }

    let avatarImageView: UIImageView = {
        let avatar = UIImageView(image: UIImage(named: "profile"))
        avatar.translatesAutoresizingMaskIntoConstraints = false
        return avatar
    }()

    let userInfoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Fonts.primaryText
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    init() {
        super.init(frame: .zero)
        layout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateUserInfo() {
        guard let userInfo = userInfo else {
            userInfoLabel.text = nil
            return
        }
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.heavyText,
            .foregroundColor: Colors.heavyText,
        ]
        let infoAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.primaryText,
            .foregroundColor: Colors.primaryText,
        ]
        let nameString = NSAttributedString(
            string: "\(userInfo.name ?? "{name}")\n",
            attributes: nameAttributes
        )
        let infoString = NSAttributedString(
            string: "\(userInfo.email ?? "{email}")\n\(userInfo.phone ?? "{phone}")\nPostal Code: \(userInfo.postalCode ?? "{postal code}")",
            attributes: infoAttributes
        )
        let combination = NSMutableAttributedString()
        combination.append(nameString)
        combination.append(infoString)

        userInfoLabel.attributedText = combination
    }

    func layout() {
        backgroundColor = Colors.white
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(avatarImageView)
        addSubview(userInfoLabel)

        NSLayoutConstraint.activate([
            // center avatar
            avatarImageView.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            avatarImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),

            // TODO: Handle dynamic type size - this will overflow if it grows too large
            userInfoLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 20),
            userInfoLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            userInfoLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
        addBankShadow()
    }
}

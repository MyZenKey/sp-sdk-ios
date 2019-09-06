//
//  TransfersViewController.swift
//  BankApp
//
//  Created by Adam Tierney on 9/5/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import UIKit

class TransfersViewController: BankAppViewController {

    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.text = "Your transfer has succeeded"
        return label
    }()

    let okayButton: UIButton = {
        let button = BankAppButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Okay", for: .normal)
        button.backgroundColor = AppTheme.primaryBlue
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        let safeAreaGuide = getSafeLayoutGuide()

        view.addSubview(titleLabel)
        view.addSubview(okayButton)

        okayButton.addTarget(self, action: #selector(okayPressed), for: .touchUpInside)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            okayButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            okayButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48),
            okayButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48),
            okayButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    @objc func okayPressed() {
        sharedRouter.pop(animated: true)
    }
}

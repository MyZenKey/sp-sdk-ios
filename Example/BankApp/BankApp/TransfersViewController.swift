//
//  TransfersViewController.swift
//  BankApp
//
//  Created by Adam Tierney on 9/5/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import UIKit

class TransfersViewController: UIViewController {

    let backgroundGradient = BackgroundGradientView()

    let successStackView: UIStackView = {
        let success = UIStackView()
        success.axis = .vertical
        success.distribution = .equalSpacing
        success.spacing = 30
        success.translatesAutoresizingMaskIntoConstraints = false
        return success
    }()

    let successLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.primaryText
        label.text = "Success!"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let checkBoxAsset: UIImageView = {
        let asset = UIImage(named: "checkbox")
        let imageView = UIImageView(image: asset!)
        return imageView
    }()


    let successInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.heavyText.withSize(17)
        label.text = "You have sent \(ApproveViewController.transaction.amount) USD to \(ApproveViewController.transaction.recipiant)."
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()


    let doneButton: UIButton = {
        let button = BankAppButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Done", for: .normal)
        button.backgroundColor = UIColor.init(red: 37.0 / 255.0, green: 67.0 / 255.0, blue: 141.0 / 255.0, alpha: 1.0)
        return button
    }()

    let demoLabel: UILabel = {
        let demo = UILabel()
        demo.text = "THIS APP IS FOR DEMO PURPOSES ONLY"
        demo.font = UIFont.primaryText.withSize(10)
        demo.textAlignment = .center
        demo.translatesAutoresizingMaskIntoConstraints = false
        return demo
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Confirmation"
        layoutView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = true
    }

    @objc func okayPressed() {
        sharedRouter.pop(animated: true)
    }

    func layoutView() {
        // Hierarchy
        view.addSubview(backgroundGradient)
        view.addSubview(successStackView)
        view.addSubview(doneButton)
        view.addSubview(demoLabel)

        successStackView.addArrangedSubview(successLabel)
        successStackView.addArrangedSubview(checkBoxAsset)
        successStackView.addArrangedSubview(successInfoLabel)

        doneButton.addTarget(self, action: #selector(okayPressed), for: .touchUpInside)

        // Style
        let safeAreaGuide = getSafeLayoutGuide()
        backgroundGradient.frame = view.bounds
        view.layer.insertSublayer(backgroundGradient.gradientLayer, at: 0)

        // Constraints
        var constraints: [NSLayoutConstraint] = []

        constraints.append(successStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(successStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -(view.bounds.height / 12)))

        constraints.append(doneButton.bottomAnchor.constraint(equalTo: demoLabel.topAnchor, constant: -16))
        constraints.append(doneButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: -25))
        constraints.append(doneButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: 25))

        constraints.append(demoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(demoLabel.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor, constant: -12))

        NSLayoutConstraint.activate(constraints)

    }
}

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
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()


    let successInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.heavyText.withSize(17)
        label.text = "You have sent \(ApproveViewController.transaction.amount) USD to \(ApproveViewController.transaction.recipiant)."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
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

    let transactionNumberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.heavyText.withSize(13)
        label.text = "Transaction number"
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let transactionNumberLiteralLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.heavyText.withSize(13)
        label.text = "#\(ApproveViewController.transaction.id)"
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var underlineView = UIView()

    let demoLabel: UILabel = {
        let demo = UILabel()
        demo.text = "THIS APP IS FOR DEMO PURPOSES ONLY."
        demo.font = UIFont.primaryText.withSize(10)
        demo.textAlignment = .center
        demo.translatesAutoresizingMaskIntoConstraints = false
        return demo
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Confirmation"
        self.navigationItem.setHidesBackButton(true, animated:true)
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
        view.addSubview(transactionNumberLabel)
        view.addSubview(transactionNumberLiteralLabel)
        view.addSubview(doneButton)
        view.addSubview(demoLabel)
        view.addSubview(underlineView)

        successStackView.addArrangedSubview(successLabel)
        successStackView.addArrangedSubview(checkBoxAsset)
        successStackView.addArrangedSubview(successInfoLabel)

        doneButton.addTarget(self, action: #selector(okayPressed), for: .touchUpInside)

        // Style
        let safeAreaGuide = getSafeLayoutGuide()
        backgroundGradient.frame = view.bounds

        view.layer.insertSublayer(backgroundGradient.gradientLayer, at: 0)
        underlineView.backgroundColor = UIColor(white: 151.0 / 255.0, alpha: 1.0)
        underlineView.translatesAutoresizingMaskIntoConstraints = false

        // Constraints
        var constraints: [NSLayoutConstraint] = []

        constraints.append(successStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(successStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -(view.bounds.height / 12)))
        constraints.append(successStackView.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 68))
        constraints.append(successStackView.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -68))

        constraints.append(transactionNumberLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 25))
        constraints.append(transactionNumberLabel.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -33))

        constraints.append(transactionNumberLiteralLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -25))
        constraints.append(transactionNumberLiteralLabel.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -33))

        constraints.append(underlineView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25))
        constraints.append(underlineView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25))
        constraints.append(underlineView.topAnchor.constraint(equalTo: transactionNumberLabel.bottomAnchor, constant: 3))
        constraints.append(underlineView.heightAnchor.constraint(equalToConstant: 1))

        constraints.append(doneButton.bottomAnchor.constraint(equalTo: demoLabel.topAnchor, constant: -16))
        constraints.append(doneButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 25))
        constraints.append(doneButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -25))
        doneButton.frame.size.height = 40

        constraints.append(demoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(demoLabel.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor, constant: -12))

        NSLayoutConstraint.activate(constraints)

    }
}

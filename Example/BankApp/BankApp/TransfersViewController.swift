//
//  TransfersViewController.swift
//  BankApp
//
//  Created by Adam Tierney on 9/5/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import UIKit

class TransfersViewController: UIViewController {

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

    let checkCircleView: UIImageView = {
        let asset = UIImage(named: "checkbox")
        let imageView = UIImageView(image: asset)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let successInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.heavyText.withSize(17)
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
        button.backgroundColor = Colors.brightAccent.value
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

    private var serviceAPI: ServiceProviderAPIProtocol = BuildInfo.serviceProviderAPI()

    override func loadView() {
        let backgroundGradient = GradientView()
        backgroundGradient.startColor = Colors.white.value
        backgroundGradient.midColor = Colors.gradientMid.value
        backgroundGradient.endColor = Colors.gradientMax.value
        backgroundGradient.startLocation = 0.0
        backgroundGradient.midLocation = 0.45
        backgroundGradient.endLocation = 1.0
        backgroundGradient.midPointMode = true
        view = backgroundGradient
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Confirmation"
        self.navigationItem.setHidesBackButton(true, animated:true)
        // fetch data
        serviceAPI.getTransactions() { [weak self] transactions,_ in
            guard let newTransactions = transactions else {
                return
            }
            self?.updateWithTransaction(transaction: newTransactions)
        }
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

    func updateWithTransaction(transaction: [Transaction]) {
        if let mostRecentTransaction = transaction.last {
            transactionNumberLiteralLabel.text = "#\(mostRecentTransaction.id)"
            successInfoLabel.text = "You have sent \(mostRecentTransaction.amount) USD \nto \(mostRecentTransaction.recipiant)."
        } else {
            return
        }
    }


    func layoutView() {

        // Hierarchy
        view.addSubview(successStackView)
        view.addSubview(demoLabel)
        view.addSubview(doneButton)
        view.addSubview(underlineView)
        view.addSubview(transactionNumberLabel)
        view.addSubview(transactionNumberLiteralLabel)

        successStackView.addArrangedSubview(successLabel)
        successStackView.addArrangedSubview(checkCircleView)
        successStackView.addArrangedSubview(successInfoLabel)

        doneButton.addTarget(self, action: #selector(okayPressed), for: .touchUpInside)

        // Style
        let safeAreaGuide = getSafeLayoutGuide()

        underlineView.backgroundColor = Colors.brownGrey.value
        underlineView.translatesAutoresizingMaskIntoConstraints = false

        // Constraints
        NSLayoutConstraint.activate([

            successStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            successStackView.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 68),
            successStackView.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -68),
            NSLayoutConstraint(item: successStackView, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 0.8, constant: 0),

            demoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            demoLabel.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor, constant: -8),

            doneButton.bottomAnchor.constraint(equalTo: demoLabel.topAnchor, constant: -16),
            doneButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 25),
            doneButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -25),
            doneButton.heightAnchor.constraint(equalToConstant: 40),

            underlineView.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 25),
            underlineView.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -25),
            underlineView.topAnchor.constraint(equalTo: transactionNumberLabel.bottomAnchor, constant: 3),
            underlineView.heightAnchor.constraint(equalToConstant: 1),

            transactionNumberLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 25),
            transactionNumberLabel.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -33),
            transactionNumberLiteralLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -25),
            transactionNumberLiteralLabel.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -33),

            ])
    }
}

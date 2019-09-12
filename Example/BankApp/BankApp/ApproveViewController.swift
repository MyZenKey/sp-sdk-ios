//
//  ApproveViewController.swift
//  BankApp
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import ZenKeySDK

class ApproveViewController: BankAppViewController {

    static let transaction = Transaction(time: Date(), recipiant: "nmel1234", amount: "$100.00")

    let promptLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Would you like to transfer \(ApproveViewController.transaction.amount) to \(ApproveViewController.transaction.recipiant)?"
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    let cancelButton: BankAppButton = {
        let button = BankAppButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Cancel", for: .normal)
        button.addTarget(self, action: #selector(cancelTransaction(_:)), for: .touchUpInside)
        button.backgroundColor = AppTheme.primaryBlue
        return button
    }()

    private var serviceAPI: ServiceProviderAPIProtocol = BuildInfo.serviceProviderAPI()

    let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.stopAnimating()
        return indicator
    }()

    let nonce = RandomStringGenerator.generateNonceSuitableString()!
    let context = ApproveViewController.transaction.contextString()

    lazy var zenKeyButton: ZenKeyAuthorizeButton = {
        let button = ZenKeyAuthorizeButton()
        button.style = .dark
        let scopes: [Scope] = [.openid, .authorize]
        button.scopes = scopes
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self
        button.acrValues = [.aal2]
        // TODO: new nonce per-press when we make this more realistic.
        button.nonce = nonce
        button.context = context
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        layoutView()
    }

    @objc func cancelTransaction(_ sender: Any) {
        if zenKeyButton.isAuthorizing {
            zenKeyButton.cancel()
        } else {
            sharedRouter.pop(animated: true)
        }
    }

    func completeFlow(withAuthChode code: String, redirectURI: URL, mcc: String, mnc: String) {
        serviceAPI.requestTransfer(
            withAuthCode: code,
            redirectURI: redirectURI,
            transaction: ApproveViewController.transaction,
            nonce: nonce) { completeTransaction, error in

                guard error == nil else {
                    self.showAlert(title: "Error", message: "A problem occured with this transaction. \(error!)") { [weak self] in
                        self?.sharedRouter.pop(animated: true)
                    }
                    return
                }
                guard let newTransaction = completeTransaction else {
                    self.showAlert(title: "Error", message: "Transaction data missing") { [weak self] in
                        self?.sharedRouter.pop(animated: true)
                    }
                    return
                }
                // transfer complete, log to activity history and present success
                var transactions = UserAccountStorage.getTransactionHistory()
                transactions.append(newTransaction)
                UserAccountStorage.setTransactionHistory(transactions)
                self.sharedRouter.showTransfersScreen(animated: true)

        }
    }

    func showActivityIndicator() {
        activityIndicator.startAnimating()
    }

    func hideActivityIndicator() {
        activityIndicator.stopAnimating()
    }

    func layoutView() {
        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let safeAreaGuide = getSafeLayoutGuide()
        
        view.addSubview(promptLabel)
        view.addSubview(zenKeyButton)
        view.addSubview(cancelButton)
        view.addSubview(activityIndicator)

        constraints.append(promptLabel.topAnchor.constraint(equalTo: gradientView.bottomAnchor, constant: 100))
        constraints.append(promptLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(promptLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))

        constraints.append(zenKeyButton.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -10))
        constraints.append(zenKeyButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48))
        constraints.append(zenKeyButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48))

        constraints.append(cancelButton.bottomAnchor.constraint(equalTo: illustrationPurposes.topAnchor, constant: -30))
        constraints.append(cancelButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48))
        constraints.append(cancelButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48))
        constraints.append(cancelButton.heightAnchor.constraint(equalTo: zenKeyButton.heightAnchor))

        constraints.append(activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor))

        NSLayoutConstraint.activate(constraints)
    }
}

extension ApproveViewController: ZenKeyAuthorizeButtonDelegate {

    func buttonWillBeginAuthorizing(_ button: ZenKeyAuthorizeButton) {
        showActivityIndicator()
        zenKeyButton.isEnabled = false
    }

    func buttonDidFinish(_ button: ZenKeyAuthorizeButton, withResult result: AuthorizationResult) {
        defer {
            hideActivityIndicator()
            zenKeyButton.isEnabled = true
        }

        switch result {
        case .code(let response):
            completeFlow(withAuthChode: response.code,
                         redirectURI: response.redirectURI,
                         mcc: response.mcc,
                         mnc: response.mnc)

        case .error(let error):
            completeFlow(withError: error)

        case .cancelled:
            cancelFlow()
        }
    }
}

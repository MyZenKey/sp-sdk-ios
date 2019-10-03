//
//  ApproveViewController.swift
//  BankApp
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import ZenKeySDK

class ApproveViewController: UIViewController {

    static let transaction = Transaction(time: Date(), recipiant: "John Doe", amount: "$100.00", id: ApproveViewController.createID())

    static func createID() -> String {
        var num = ""
        for _ in 0 ... 10 {
            num.append(String(Int.random(in: 0 ..< 10)))
        }
        print(num)
        return num
    }

    let backgroundGradient = BackgroundGradientView()

    let transferLabel: UILabel = {
        let label = UILabel()
        label.text = "Transfer Amount"
        label.font = UIFont.primaryText
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let amountLabel: UILabel = {
        let amount = UILabel()
        amount.text = ApproveViewController.transaction.amount
        amount.font = UIFont.heavyText
        amount.textAlignment = .center
        amount.translatesAutoresizingMaskIntoConstraints = false
        return amount
    }()

    let johnDoeAvatar: UIImageView = {
        let jdavatar = UIImage(named: "jd-transfer")
        let imageView = UIImageView(image: jdavatar)
        return imageView
    }()

    let transferInfoStackView: UIStackView = {
        let transfer = UIStackView()
        transfer.axis = .vertical
        transfer.distribution = .equalSpacing
        transfer.spacing = 30
        transfer.translatesAutoresizingMaskIntoConstraints = false
        return transfer
    }()

    let demoLabel: UILabel = {
        let demo = UILabel()
        demo.text = "THIS APP IS FOR DEMO PURPOSES ONLY"
        demo.font = UIFont.primaryText.withSize(10)
        demo.textAlignment = .center
        demo.translatesAutoresizingMaskIntoConstraints = false
        return demo
    }()

    private var serviceAPI: ServiceProviderAPIProtocol = BuildInfo.serviceProviderAPI()

    let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .gray)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.stopAnimating()
        return indicator
    }()

    let nonce = RandomStringGenerator.generateNonceSuitableString()!
    let context = ApproveViewController.transaction.contextString

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
<<<<<<< HEAD

=======
>>>>>>> task/XCI-4982-update-send-money
        self.title = "Send Money"
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
        // Hierarchy
        view.addSubview(transferInfoStackView)
        view.addSubview(zenKeyButton)
        view.addSubview(activityIndicator)
        view.addSubview(demoLabel)

        transferInfoStackView.addArrangedSubview(transferLabel)
        transferInfoStackView.addArrangedSubview(amountLabel)
        transferInfoStackView.addArrangedSubview(johnDoeAvatar)

        // Style
        let safeAreaGuide = getSafeLayoutGuide()

        // Constraints
<<<<<<< HEAD
        var constraints: [NSLayoutConstraint] = []

        constraints.append(transferInfoStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(transferInfoStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -(view.bounds.height / 12)))
        constraints.append(transferInfoStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25))
        constraints.append(transferInfoStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25))

        constraints.append(zenKeyButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48))
        constraints.append(zenKeyButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48))
        constraints.append(zenKeyButton.bottomAnchor.constraint(equalTo: demoLabel.topAnchor, constant: -40))

        constraints.append(activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor))

        constraints.append(demoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(demoLabel.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor, constant: -12))


        NSLayoutConstraint.activate(constraints)
=======
        NSLayoutConstraint.activate([

            NSLayoutConstraint(item: transferInfoStackView, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 0.8, constant: 0),
            transferInfoStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            transferInfoStackView.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 25),
            transferInfoStackView.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -25),

            zenKeyButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 25),
            zenKeyButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -25),
            zenKeyButton.bottomAnchor.constraint(equalTo: demoLabel.topAnchor, constant: -40),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            demoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            demoLabel.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor, constant: -12),

            ])
>>>>>>> task/XCI-4982-update-send-money
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

extension UIFont { //FIXME: Refactor fonts to be system-wide
    class var primaryText: UIFont {
        return UIFont.systemFont(ofSize: 42.0, weight: .thin)
    }
    class var heavyText: UIFont {
        return UIFont.systemFont(ofSize: 52.0, weight: .regular)
    }
}

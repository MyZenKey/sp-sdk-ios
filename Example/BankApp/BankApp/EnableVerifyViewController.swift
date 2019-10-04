//
//  EnableVerifyViewController.swift
//  BankApp
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import ZenKeySDK

class EnableVerifyViewController: UIViewController {

    let backgroundClouds: UIImageView = {
        let clouds = UIImage(named: "clouds")
        let cloudsImage = UIImageView(image: clouds)
        return cloudsImage
    }()

    let zenkeyLogo: UIImageView = {
        let zenkey = UIImage(named: "zenKeyLogo")
        let zenkeyImage = UIImageView(image: zenkey)
        return zenkeyImage
    }()

    let centralSymbol: UIImageView = {
        let symbol = UIImage(named: "interstitialSymbol")
        let centerSymbol = UIImageView(image: symbol)
        return centerSymbol
    }()

    let approvalLabel: UILabel = {
        let approve = UILabel()
        approve.text = "Would you like to use ZenKey to \napprove future \"Bank App\" logins?"
        approve.font = UIFont.heavyText.withSize(17)
        approve.textAlignment = .center
        approve.translatesAutoresizingMaskIntoConstraints = false
        return approve
    }()

    let symbolLogoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .equalSpacing
        stack.spacing = 33
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    lazy var zenKeyButton: ZenKeyAuthorizeButton = {
        let button = ZenKeyAuthorizeButton()
        button.style = .dark
        let scopes: [Scope] = [.openid, .secondFactor]
        button.scopes = scopes
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self
        return button
    }()

    let cancelButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("No, thanks", for: .normal)
        button.addTarget(self, action: #selector(cancelVerify(_:)), for: .touchUpInside)
        button.setTitleColor(Colors.mediumAccent.value, for: .normal)
        button.titleLabel?.font = UIFont.mediumText
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

    private let serviceAPI: ServiceProviderAPIProtocol = BuildInfo.serviceProviderAPI()

    override func loadView() {
        let gradient = GradientView()
        gradient.startColor = Colors.ice.value
        gradient.midColor = Colors.ice.value
        gradient.endColor = Colors.white.value

        gradient.startLocation = 0.0
        gradient.midLocation = 0.32
        gradient.endLocation = 0.68

        gradient.midPointMode = true
        view = gradient
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "We Support ZenKey"
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

    
    @objc func cancelVerify(_ sender: Any) {
        sharedRouter.popToRoot(animated: true)
    }

    func layoutView() {
        // Heirarchy
        symbolLogoStackView.addArrangedSubview(zenkeyLogo)
        symbolLogoStackView.addArrangedSubview(centralSymbol)

        view.addSubview(backgroundClouds)
        view.addSubview(symbolLogoStackView)
        view.addSubview(approvalLabel)
        view.addSubview(zenKeyButton)
        view.addSubview(cancelButton)
        view.addSubview(demoLabel)
        
        // Style
        let safeAreaGuide = getSafeLayoutGuide()

        // Layout
        NSLayoutConstraint.activate([

            NSLayoutConstraint(item: symbolLogoStackView, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 0.8, constant: 0),

            symbolLogoStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            symbolLogoStackView.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48),
            symbolLogoStackView.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -47),
            ])
    }
}

extension EnableVerifyViewController: ZenKeyAuthorizeButtonDelegate {

    func buttonWillBeginAuthorizing(_ button: ZenKeyAuthorizeButton) { }

    func buttonDidFinish(_ button: ZenKeyAuthorizeButton, withResult result: AuthorizationResult) {
        switch result {
        case .code(let authorizedResponse):
            authorizeUser(authorizedResponse: authorizedResponse)
        case .error(let error):
            completeFlow(withError: error)
        case .cancelled:
            cancelFlow()
        }
    }

    func authorizeUser(authorizedResponse: AuthorizedResponse) {
        let code = authorizedResponse.code
        serviceAPI.addSecondFactor(
            withAuthCode: code,
            redirectURI: authorizedResponse.redirectURI,
            mcc: authorizedResponse.mcc,
            mnc: authorizedResponse.mnc,
            completion: { [weak self] authResponse, error in
                guard
                    let accountToken = authResponse?.token else {
                        print("error no token returned")
                        self?.showAlert(title: "Error", message: "error logging in \(String(describing: error))")
                        return
                }

                AccountManager.login(withToken: accountToken)
                self?.sharedRouter.startAppFlow()
        })
    }
}

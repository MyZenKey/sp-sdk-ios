//
//  EnableVerifyViewController.swift
//  BankApp
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import ZenKeySDK

class EnableVerifyViewController: BankAppViewController {
    let cancelButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("No, thanks", for: .normal)
        button.addTarget(self, action: #selector(cancelVerify(_:)), for: .touchUpInside)
        button.setTitleColor(UIColor(red: 0.36, green: 0.56, blue: 0.93, alpha: 1.0), for: .normal)
        return button
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let text = "We now support\nZenKey"
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttributes([NSAttributedStringKey.font :  UIFont.italicSystemFont(ofSize: 38), NSAttributedStringKey.foregroundColor:UIColor.black], range: (text as NSString).range(of: "ZenKey"))
        label.attributedText = attributedString
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let text = "Would you like to use ZenKey to approve future Bank App logins?"
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttributes([NSAttributedStringKey.font :  UIFont.italicSystemFont(ofSize: 18), NSAttributedStringKey.foregroundColor:UIColor.black], range: (text as NSString).range(of: "ZenKey"))
        label.attributedText = attributedString
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
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

    private let clientSideServiceAPI: ServiceAPIProtocol = ClientSideServiceAPI()

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutView()
    }
    
    @objc func cancelVerify(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }

    func layoutView() {
        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let safeAreaGuide = getSafeLayoutGuide()
        
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(cancelButton)
        view.addSubview(zenKeyButton)
        
        constraints.append(titleLabel.topAnchor.constraint(equalTo: gradientView.bottomAnchor, constant: 100))
        constraints.append(titleLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(titleLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))
        
        constraints.append(descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20))
        constraints.append(descriptionLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(descriptionLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))

        constraints.append(zenKeyButton.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -25))
        constraints.append(zenKeyButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48))
        constraints.append(zenKeyButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48))

        constraints.append(cancelButton.bottomAnchor.constraint(equalTo: illustrationPurposes.topAnchor, constant: -25))
        constraints.append(cancelButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48))
        constraints.append(cancelButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48))
        constraints.append(cancelButton.heightAnchor.constraint(equalToConstant: 48))

        NSLayoutConstraint.activate(constraints)
        
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
        clientSideServiceAPI.addSecondFactor(
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
                self?.launchHomeScreen()
        })
    }
}

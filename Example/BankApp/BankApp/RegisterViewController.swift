//
//  RegisterViewController.swift
//  BankApp
//
//  Created by Adam Tierney on 9/6/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import UIKit
import ZenKeySDK

class RegisterViewController: BankAppViewController {

    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.text = "Sign Up for BankApp"
        label.textAlignment = .center
        return label
    }()

    let userNameTextField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.borderStyle = .roundedRect
        field.minimumFontSize = 17
        field.placeholder = "Username"
        return field
    }()

    let emailTextField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.borderStyle = .roundedRect
        field.minimumFontSize = 17
        field.placeholder = "Email"
        return field
    }()

    let passwordTextField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.borderStyle = .roundedRect
        field.minimumFontSize = 17
        field.isSecureTextEntry = true
        field.placeholder = "Password"
        return field
    }()

    let confirmPasswordTextField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.borderStyle = .roundedRect
        field.minimumFontSize = 17
        field.isSecureTextEntry = true
        field.placeholder = "Confirm Password"
        return field
    }()

    let postalCodeTextField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.borderStyle = .roundedRect
        field.minimumFontSize = 17
        field.placeholder = "Postal Code"
        return field
    }()

    let signUpButton: UIButton = {
        let button = BankAppButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Sign Up", for: .normal)
        button.backgroundColor = AppTheme.primaryBlue
        return button
    }()

    let dividerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.text = "- Or -"
        label.textAlignment = .center
        return label
    }()

    lazy var zenKeyButton: ZenKeyAuthorizeButton = {
        let button = ZenKeyAuthorizeButton()
        button.style = .dark
        let scopes: [Scope] = [.openid, .register, .name, .email, .postalCode]
        button.scopes = scopes
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self
        return button
    }()

    private var serviceAPI: ServiceProviderAPIProtocol = BuildInfo.serviceProviderAPI()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        let safeAreaGuide = getSafeLayoutGuide()

        isNavigationCancelButtonHidden = false

        view.addSubview(titleLabel)
        view.addSubview(userNameTextField)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(confirmPasswordTextField)
        view.addSubview(postalCodeTextField)
        view.addSubview(signUpButton)
        view.addSubview(dividerLabel)
        view.addSubview(zenKeyButton)

        signUpButton.addTarget(self, action: #selector(signUpPressed), for: .touchUpInside)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: gradientView.bottomAnchor, constant: 48),
            titleLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48),
            titleLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48),

            userNameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            userNameTextField.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48),
            userNameTextField.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48),

            emailTextField.topAnchor.constraint(equalTo: userNameTextField.bottomAnchor, constant: 10),
            emailTextField.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48),
            emailTextField.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48),

            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 10),
            passwordTextField.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48),
            passwordTextField.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48),

            confirmPasswordTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 10),
            confirmPasswordTextField.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48),
            confirmPasswordTextField.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48),

            postalCodeTextField.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor, constant: 10),
            postalCodeTextField.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48),
            postalCodeTextField.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48),

            signUpButton.topAnchor.constraint(equalTo: postalCodeTextField.bottomAnchor, constant: 10),
            signUpButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48),
            signUpButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48),
            signUpButton.heightAnchor.constraint(equalToConstant: 40),

            dividerLabel.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 20),
            dividerLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48),
            dividerLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48),

            zenKeyButton.topAnchor.constraint(equalTo: dividerLabel.bottomAnchor, constant: 20),
            zenKeyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            zenKeyButton.widthAnchor.constraint(equalTo: signUpButton.widthAnchor),
        ])
    }

    @objc func signUpPressed() {
        showAlert(
            title: "Not Supported",
            message: "We don't support manual sign up yet, try ZenKey instead!"
        )
    }
}

extension RegisterViewController: ZenKeyAuthorizeButtonDelegate {

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
        serviceAPI.login(
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

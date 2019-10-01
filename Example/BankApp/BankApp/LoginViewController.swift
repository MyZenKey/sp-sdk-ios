//
//  LoginViewController.swift
//  BankApp
//
//  Created by Adam Tierney on 9/30/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit
import ZenKeySDK

final class LoginViewController: UIViewController {

    private let logo: UIImageView = {
        let logo = UIImageView(image: UIImage(named: "bankapp-logo"))
        logo.translatesAutoresizingMaskIntoConstraints = false
        return logo
    }()

    private let backgroundImage: UIImageView = {
        let backgroundImage = UIImageView(image: UIImage(named: "login-background-image"))
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        backgroundImage.contentMode = .scaleAspectFill
        return backgroundImage
    }()

    lazy var zenkeyButton: ZenKeyAuthorizeButton = {
        let button = ZenKeyAuthorizeButton()
        let scopes: [Scope] = [.openid, .authenticate, .name, .email, .postalCode, .phone]
        button.scopes = scopes
        button.translatesAutoresizingMaskIntoConstraints = false
        button.brandingDelegate = self
        button.delegate = self
        button.accessibilityIdentifier = "ZenKey Button"
        return button
    }()

    private let usernameTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.placeholder = "User ID"
        return field
    }()
    
    let passwordTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.placeholder = "Password"
        return field
    }()
    
    private let signInButton: BankAppButton = {
        // TODO: - prioritize a refactor of this type
        let button = BankAppButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.borderWidth = 2.0

        button.setTitle("Sign In", for: .normal)
        button.addTarget(self, action: #selector(signInButtonPressed), for: .touchUpInside)

        button.borderColor = Colors.brightAccent.value
        button.backgroundColor = Colors.brightAccent.value

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 40.0)
        ])

        return button
    }()

    private let forgotPassowrdButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setAttributedTitle(
            NSAttributedString(
                string: "Forgot User ID or Password?",
                attributes: [
                    .font: Fonts.accesory,
                    .foregroundColor: Colors.heavyText.value,
                    .kern: 0.2
                ]),
            for: .normal
        )
        return button
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setAttributedTitle(
            NSAttributedString(
                string: "Sign up for BankApp",
                attributes: [
                    .font: Fonts.accesory,
                    .foregroundColor: Colors.brightAccent.value,
                    .kern: 0.2
                ]),
            for: .normal
        )
        button.addTarget(self, action: #selector(registerButtonPressed), for: .touchUpInside)
        return button
    }()

    // TODO: -
    private let poweredByLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    private let demoPurposesLabel: UILabel = UIViewController.makeDemoPurposesLabel()

//    private lazy var inputToolbar: UIToolbar = {
//        let toolbar = UIToolbar()
//        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
//        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
//        toolbar.items = [flex, doneButton]
//        toolbar.sizeToFit()
//        return toolbar
//    }()

    private lazy var buttonsStack: UIStackView = {
        let orDivider = OrDividerView()
        let stackView = UIStackView(arrangedSubviews: [
            zenkeyButton,
            orDivider,
            usernameTextField,
            passwordTextField,
            signInButton,
            forgotPassowrdButton,
        ])

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 22
        stackView.isLayoutMarginsRelativeArrangement = true
        let marign: CGFloat = 15
        stackView.layoutMargins = UIEdgeInsets(top: marign, left: marign, bottom: marign, right: marign)

        stackView.setCustomSpacing(15, after: zenkeyButton)
        stackView.setCustomSpacing(15, after: orDivider)
        stackView.setCustomSpacing(15, after: signInButton)

        return stackView
    }()

    /// Stack view doesn't draw so mirror it's size and add a shadow to this view:
    private lazy var buttonStackViewContainer: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = Colors.white.value

        view.layer.shadowColor = Colors.shadow.value.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4.0
        view.layer.shadowOpacity = 0.24

        view.addSubview(buttonsStack)

        NSLayoutConstraint.activate([
            buttonsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonsStack.topAnchor.constraint(equalTo: view.topAnchor),
            buttonsStack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        return view
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            buttonStackViewContainer,
            registerButton,
            demoPurposesLabel
        ])

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 25

        stackView.setCustomSpacing(15, after: registerButton)

        return stackView
    }()

    private let serviceAPI: ServiceProviderAPIProtocol = BuildInfo.serviceProviderAPI()

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutView()
    }

    func layoutView() {
        DebugViewController.addMenu(toViewController: self)

        view.backgroundColor = Colors.white.value

        let safeAreaGuide = getSafeLayoutGuide()

        view.addSubview(backgroundImage)
        view.addSubview(logo)
        view.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            // postioned relative to the very bottom of the view and it's edges regardless of
            // marigns.
            logo.widthAnchor.constraint(lessThanOrEqualTo: safeAreaGuide.widthAnchor),
            logo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logo.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor),

            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Constants.bottomAreaHeight),
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),

            contentStackView.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])
    }

    // MARK: -  Actions

    @objc func registerButtonPressed() {
        sharedRouter.showRegisterViewController(animated: true)
    }

    @objc func signInButtonPressed() {
        serviceAPI.login(
            withUsername: usernameTextField.text?.lowercased() ?? "",
            password: passwordTextField.text?.lowercased() ?? "") { [weak self] auth, error in

                guard auth != nil, error == nil else {
                    self?.showAlert(
                        title: "Enter User Name and password",
                        message: "You must enter your user name and password to log in.\nHint: try username: jane and password: 12345"
                    )
                    return
                }

                self?.sharedRouter.showEnableVerifyViewController(animated: true)
        }
    }

    @objc func dismissKeyboard() {
        usernameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
}

private extension LoginViewController {
    enum Constants {
        /// the 'reserved' white area at the bottom of the screen's height
        static let bottomAreaHeight: CGFloat = 175
        static let buttonStackLowerMargin: CGFloat = 75
    }
}

extension LoginViewController: ZenKeyAuthorizeButtonDelegate {

    func buttonWillBeginAuthorizing(_ button: ZenKeyAuthorizeButton) {
        zenkeyButton.acrValues = [BuildInfo.currentAuthMode]
    }

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

extension LoginViewController: ZenKeyBrandedButtonDelegate {
    func brandingWillUpdate(_ oldBranding: Branding,
                            forButton button: ZenKeyBrandedButton) { }

    func brandingDidUpdate(_ newBranding: Branding,
                           forButton button: ZenKeyBrandedButton) {
        poweredByLabel.text = newBranding.carrierText
    }
}

//
//  RegisterViewController.swift
//  BankApp
//
//  Created by Adam Tierney on 9/6/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import UIKit
import ZenKeySDK

class RegisterViewController: ScrollingContentViewController {

    private let backgroundImage: UIImageView = {
        let backgroundImage = UIImageView(image: UIImage(named: "signup-background-image"))
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        backgroundImage.contentMode = .scaleAspectFill
        return backgroundImage
    }()

    lazy var zenkeyButton: ZenKeyAuthorizeButton = {
        let button = ZenKeyAuthorizeButton()
        button.style = .dark
        let scopes: [Scope] = [.openid, .register, .name, .email, .postalCode, .phone]
        button.scopes = scopes
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self
        return button
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.text = "Sign Up for BankApp"
        label.textAlignment = .center
        return label
    }()

    let userNameTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.placeholder = "User ID"
        return field
    }()

    let emailTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.placeholder = "Email"
        return field
    }()

    let phoneTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.placeholder = "Phone Number"
        return field
    }()

    let passwordTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.placeholder = "Password"
        return field
    }()

    let confirmPasswordTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.placeholder = "Confirm Password"
        return field
    }()

    let postalCodeTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.placeholder = "Postal Code"
        return field
    }()

    let signUpButton: UIButton = {
        let button = BankAppButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.borderWidth = 2.0
        button.setTitle("Sign Up", for: .normal)
        button.borderColor = Colors.brightAccent.value
        button.backgroundColor = Colors.brightAccent.value

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 40.0)
        ])

        return button
    }()

    private let demoPurposesLabel: UILabel = UIViewController.makeDemoPurposesLabel()

    private lazy var formStack: UIStackView = {
        let orDivider = OrDividerView()
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            zenkeyButton,
            orDivider,
            userNameTextField,
            emailTextField,
            phoneTextField,
            passwordTextField,
            confirmPasswordTextField,
            postalCodeTextField,
            signUpButton,
        ])

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 22
        stackView.isLayoutMarginsRelativeArrangement = true

        let marign: CGFloat = Constants.mediumSpace
        stackView.layoutMargins = UIEdgeInsets(
            top: marign,
            left: marign,
            bottom: marign,
            right: marign
        )

        stackView.setCustomSpacing(Constants.smallSpace, after: zenkeyButton)
        stackView.setCustomSpacing(Constants.smallSpace, after: orDivider)

        return stackView
    }()

    /// Stack view doesn't draw so mirror it's size and add a shadow to this view:
    private lazy var formStackViewContainer: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = Colors.white.value

        view.layer.shadowColor = Colors.shadow.value.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4.0
        view.layer.shadowOpacity = 0.24

        view.addSubview(formStack)

        NSLayoutConstraint.activate([
            formStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            formStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            formStack.topAnchor.constraint(equalTo: view.topAnchor),
            formStack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        return view
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            formStackViewContainer,
            demoPurposesLabel
        ])

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = Constants.smallSpace

        return stackView
    }()


    private var serviceAPI: ServiceProviderAPIProtocol = BuildInfo.serviceProviderAPI()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Colors.white.value
        signUpButton.addTarget(self, action: #selector(signUpPressed), for: .touchUpInside)

//        scrollView.delegate = self
        updateMargins()

        contentView.addSubview(backgroundImage)
        contentView.addSubview(contentStackView)

        // try to be the screen size if able:
        let tendTowardScreenSizeConstraint = contentView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height)
        tendTowardScreenSizeConstraint.priority = .fittingSizeLevel

        NSLayoutConstraint.activate([
            tendTowardScreenSizeConstraint,

            backgroundImage.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundImage.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -Constants.bottomAreaHeight
            ),

            // we want no scrolling horizontally, so pin widths to scroll view
            backgroundImage.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            backgroundImage.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            contentStackView.bottomAnchor.constraint(
                equalTo: contentView.layoutMarginsGuide.bottomAnchor,
                constant: -8
            ),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
        ])
    }

    @objc func signUpPressed() {
        showAlert(
            title: "Not Supported",
            message: "We don't support manual sign up yet, try ZenKey instead!"
        )
    }
}

private extension RegisterViewController {
    enum Constants {
        /// the 'reserved' white area at the bottom of the screen's height
        static let bottomAreaHeight: CGFloat = 175
        static let buttonStackLowerMargin: CGFloat = 75
        static let largeSpace: CGFloat = 25
        static let mediumSpace: CGFloat = 15
        static let smallSpace: CGFloat = 10
    }

    /// The margins are not quite right out of the box, update them to reflect the horizontal marigns
    /// we expect and add no additional marign to the safe area at the bottom.
    func updateMargins() {
        var margins = contentView.layoutMargins
        margins.bottom = 0.0
        margins.left = Constants.largeSpace
        margins.right = Constants.largeSpace
        contentView.layoutMargins = margins
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

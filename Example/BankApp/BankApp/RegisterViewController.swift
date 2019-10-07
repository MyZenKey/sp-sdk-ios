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

    private lazy var zenkeyButton: ZenKeyAuthorizeButton = {
        let button = ZenKeyAuthorizeButton()
        button.style = .dark
        let scopes: [Scope] = [.openid, .register, .name, .email, .postalCode, .phone]
        button.scopes = scopes
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = Fonts.boldHeadlineText(
            text: "Start your future with BankApp.",
            withColor: Colors.primaryText.value
        )
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private let orDivider: OrDividerView = {
        let orDivider = OrDividerView()
        let height = orDivider.heightAnchor.constraint(equalToConstant: Constants.mediumSpace)
        height.isActive = true
        return orDivider
    }()

    private let userNameTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.placeholder = "User ID"
        return field
    }()

    private let emailTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.placeholder = "Email"
        return field
    }()

    private let phoneTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.placeholder = "Phone Number"
        return field
    }()

    private let passwordTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.placeholder = "Password"
        field.isSecureTextEntry = true
        return field
    }()

    private let confirmPasswordTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.placeholder = "Confirm Password"
        field.isSecureTextEntry = true
        return field
    }()

    private let postalCodeTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.placeholder = "Postal Code"
        return field
    }()

    private let signUpButton: UIButton = {
        let button = BankAppButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.buttonTitle = "Sign Up"

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 40.0)
        ])

        return button
    }()

    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let gestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTapGesture)
        )
        return gestureRecognizer
    }()

    private let demoPurposesLabel: UILabel = UIViewController.makeDemoPurposesLabel()

    private lazy var formStack: UIStackView = {
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

    private lazy var footerView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Colors.white.value
        return view
    }()

    fileprivate var cardToTopConstraint: NSLayoutConstraint!

    fileprivate var outsetConstraint: NSLayoutConstraint!

    private var serviceAPI: ServiceProviderAPIProtocol = BuildInfo.serviceProviderAPI()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Colors.white.value
        signUpButton.addTarget(self, action: #selector(signUpPressed), for: .touchUpInside)

        view.addGestureRecognizer(tapGestureRecognizer)

        scrollView.keyboardDismissMode = .onDrag

        updateMargins()

        contentView.addSubview(backgroundImage)
        contentView.addSubview(footerView)
        contentView.addSubview(contentStackView)

        // background image should shrink to support keeping the distance between card and top
        // of the screen fixed to it's desired scale.
        backgroundImage.setContentCompressionResistancePriority(.fittingSizeLevel, for: .vertical)

        cardToTopConstraint = contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor)
        outsetConstraint = backgroundImage.topAnchor.constraint(equalTo: contentView.topAnchor)

        NSLayoutConstraint.activate([

            cardToTopConstraint,
            outsetConstraint,

            backgroundImage.bottomAnchor.constraint(equalTo: footerView.topAnchor),

            // we want no scrolling horizontally, so pin widths to scroll view
            backgroundImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundImage.widthAnchor.constraint(equalTo: view.widthAnchor),

            contentStackView.bottomAnchor.constraint(
                equalTo: footerView.bottomAnchor,
                constant: -8
            ),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),

            footerView.heightAnchor.constraint(equalToConstant: Constants.bottomAreaHeight),
            footerView.widthAnchor.constraint(equalTo: view.widthAnchor),
            footerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            footerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "Register"
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // push the photo out by the amount that we get inset
        outsetConstraint.constant = -view.safeAreaInsets.top
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // on smaller screens, reduce the top float to a percentage of the screen's height
        // but don't grow over 166 for very large screens.
        cardToTopConstraint.constant = min(166, scrollView.frame.height * 0.2)
    }

    @objc func signUpPressed() {
        showAlert(
            title: "Not Supported",
            message: "We don’t support manual sign up, yet. Try ZenKey instead!"
        )
    }

    @objc func handleTapGesture() {
        [
            userNameTextField,
            emailTextField,
            phoneTextField,
            passwordTextField,
            confirmPasswordTextField,
            postalCodeTextField,
        ].forEach() { $0.resignFirstResponder() }
    }
}

private extension RegisterViewController {
    enum Constants {
        /// the 'reserved' white area at the bottom of the screen's height
        static let bottomAreaHeight: CGFloat = 157
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

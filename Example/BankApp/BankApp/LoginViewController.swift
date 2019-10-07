//
//  LoginViewController.swift
//  BankApp
//
//  Created by Adam Tierney on 9/30/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit
import ZenKeySDK

final class LoginViewController: ScrollingContentViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

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

    private let poweredByLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private let usernameTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.placeholder = "User ID"
        return field
    }()
    
    private let passwordTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.placeholder = "Password"
        field.isSecureTextEntry = true
        return field
    }()
    
    private let signInButton: BankAppButton = {
        // TODO: - The api surface area of BankAppButton is crufty and doesn’t intuitively reflect
        // the redesign requirements. Refractor for a slimmer profile.
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

    private let forgotPasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setAttributedTitle(
            Fonts.accessoryText(
                text: "Forgot User ID or Password?",
                withColor: Colors.heavyText.value
            ),
            for: .normal
        )
        return button
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setAttributedTitle(
            Fonts.accessoryText(
                text: "Sign up for BankApp",
                withColor: Colors.brightAccent.value
            ),
            for: .normal
        )
        button.addTarget(self, action: #selector(registerButtonPressed), for: .touchUpInside)
        return button
    }()

    private let demoPurposesLabel: UILabel = UIViewController.makeDemoPurposesLabel()

    private lazy var buttonsStack: UIStackView = {
        let orDivider = OrDividerView()
        let stackView = UIStackView(arrangedSubviews: [
            zenkeyButton,
            poweredByLabel,
            orDivider,
            usernameTextField,
            passwordTextField,
            signInButton,
            forgotPasswordButton,
        ])

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 22
        stackView.isLayoutMarginsRelativeArrangement = true

        let marign: CGFloat = Constants.smallSpace
        stackView.layoutMargins = UIEdgeInsets(
            top: marign,
            left: marign,
            bottom: marign - forgotPasswordButton.layoutMargins.bottom,
            right: marign
        )

        let smallerSpacer: CGFloat = Constants.smallSpace
        stackView.setCustomSpacing(smallerSpacer, after: zenkeyButton)
        stackView.setCustomSpacing(smallerSpacer, after: poweredByLabel)
        stackView.setCustomSpacing(smallerSpacer, after: orDivider)
        // text buttons don't count marign in sizing
        stackView.setCustomSpacing(
            smallerSpacer - forgotPasswordButton.layoutMargins.top,
            after: signInButton
        )

        return stackView
    }()

    /// Stack view doesn't draw so mirror it's size and add a shadow to this view:
    private lazy var buttonStackViewContainer: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = Colors.white.value

        // FIXME: - Let's abstract this out so it can be easily handled by dark mode.
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
        stackView.spacing = Constants.largeSpace

        stackView.setCustomSpacing(
            Constants.largeSpace - registerButton.layoutMargins.top,
            after: buttonStackViewContainer
        )

        stackView.setCustomSpacing(
            Constants.smallSpace - registerButton.layoutMargins.bottom,
            after: registerButton
        )

        return stackView
    }()

    private lazy var footerView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Colors.white.value
        return view
    }()

    private var outsetConstraint: NSLayoutConstraint!
    private var photoHeightRestrictionConstraint: NSLayoutConstraint!

    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let gestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTapGesture)
        )
        return gestureRecognizer
    }()

    fileprivate var outsetConstraintConstant: CGFloat {
        return -view.safeAreaInsets.top
    }

    fileprivate var photoHeightConstraintConstant: CGFloat {
        return -(Constants.bottomAreaHeight + (view.safeAreaInsets.bottom - additionalSafeAreaInsets.bottom))
    }

    private let serviceAPI: ServiceProviderAPIProtocol = BuildInfo.serviceProviderAPI()

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutView()
    }

    func layoutView() {
        DebugViewController.addMenu(toViewController: self)

        view.backgroundColor = Colors.white.value

        scrollView.keyboardDismissMode = .onDrag

        updateMargins()

        view.addGestureRecognizer(tapGestureRecognizer)
        forgotPasswordButton.addTarget(
            self,
            action: #selector(forgotPasswordButtonPressed),
            for: .touchUpInside
        )

        contentView.addSubview(backgroundImage)
        contentView.addSubview(footerView)
        contentView.addSubview(logo)
        contentView.addSubview(contentStackView)

        outsetConstraint = backgroundImage.topAnchor.constraint(equalTo: contentView.topAnchor)

        // the photo should take the space of the screen above the footer area
        photoHeightRestrictionConstraint = backgroundImage.heightAnchor.constraint(
            equalTo: scrollView.frameLayoutGuide.heightAnchor,
            constant: photoHeightConstraintConstant
        )

        NSLayoutConstraint.activate([

            photoHeightRestrictionConstraint,
            outsetConstraint,

            // postioned relative to the very bottom of the view and it's edges regardless of
            // marigns.
            logo.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor),
            logo.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logo.topAnchor.constraint(equalTo: contentView.topAnchor),

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

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // The photo should sit at the top of the screen. This will be pushed outside of the
        // scroll view's content area by the size of the safe area:
        outsetConstraint.constant = outsetConstraintConstant
        // The photo height should scale to fill the space on all screen sizes, less the bottom
        // space. This is the bottom space constant height adjusted for the unmodified safe area
        // insets:
        photoHeightRestrictionConstraint.constant = photoHeightConstraintConstant
    }

    // MARK: -  Actions

    @objc func forgotPasswordButtonPressed() {
        showPasswordReminderAlert()
    }

    @objc func registerButtonPressed() {
        sharedRouter.showRegisterViewController(animated: true)
    }

    @objc func signInButtonPressed() {
        serviceAPI.login(
            withUsername: usernameTextField.text?.lowercased() ?? "",
            password: passwordTextField.text?.lowercased() ?? "") { [weak self] auth, error in

                guard auth != nil, error == nil else {
                    self?.showPasswordReminderAlert()
                    return
                }

                self?.sharedRouter.showEnableVerifyViewController(animated: true)
        }
    }

    @objc func handleTapGesture() {
        usernameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
}

private extension LoginViewController {
    enum Constants {
        /// the 'reserved' white area at the bottom of the screen's height
        static let bottomAreaHeight: CGFloat = 175
        static let buttonStackLowerMargin: CGFloat = 75
        static let largeSpace: CGFloat = 25
        static let smallSpace: CGFloat = 15
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

    func showPasswordReminderAlert() {
        showAlert(
            title: "Enter User Name and password",
            message: "Your username is “jane” and your password is the answer to “Why was 6 afraid of 7? Because …"
        )
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
        guard
            let carrierText = newBranding.carrierText,
            !carrierText.isEmpty else {
            return
        }

        poweredByLabel.attributedText = Fonts.accessoryText(
            text: carrierText,
            withColor: Colors.heavyText.value
        )
        poweredByLabel.isHidden = false
    }
}

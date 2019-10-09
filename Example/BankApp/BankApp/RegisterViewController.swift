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
            withColor: Colors.primaryText
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
        field.attributedPlaceholder = "User ID"
        return field
    }()

    private let emailTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.attributedPlaceholder = "Email"
        return field
    }()

    private let phoneTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.attributedPlaceholder = "Phone Number"
        return field
    }()

    private let passwordTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.attributedPlaceholder = "Password"
        field.textField.isSecureTextEntry = true
        return field
    }()

    private let confirmPasswordTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.attributedPlaceholder = "Confirm Password"
        field.textField.isSecureTextEntry = true
        return field
    }()

    private let postalCodeTextField: UnderlinedTextFieldView = {
        let field = UnderlinedTextFieldView()
        field.attributedPlaceholder = "Postal Code"
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

        view.backgroundColor = Colors.white

        view.layer.shadowColor = Colors.shadow.cgColor
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
        view.backgroundColor = Colors.white
        return view
    }()

    fileprivate var outsetConstraint: NSLayoutConstraint!
    fileprivate var photoHeightRestrictionConstraint: NSLayoutConstraint!

    private var overScrollValue: CGFloat {
        return -min(0, scrollView.contentOffset.y)
    }

    fileprivate var outsetConstraintConstant: CGFloat {
        return -(view.safeAreaInsets.top + overScrollValue)
    }

    fileprivate var photoHeightConstraintConstant: CGFloat {
        return -(Constants.bottomAreaHeight + (view.safeAreaInsets.bottom - additionalSafeAreaInsets.bottom)) + overScrollValue
    }

    private var serviceAPI: ServiceProviderAPIProtocol = BuildInfo.serviceProviderAPI()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Colors.white
        signUpButton.addTarget(self, action: #selector(signUpPressed), for: .touchUpInside)

        view.addGestureRecognizer(tapGestureRecognizer)

        scrollView.keyboardDismissMode = .interactive
        scrollView.delegate = self

        updateMargins()

        contentView.addSubview(backgroundImage)
        contentView.addSubview(footerView)
        contentView.addSubview(contentStackView)

        outsetConstraint = backgroundImage.topAnchor.constraint(equalTo: contentView.topAnchor)

        photoHeightRestrictionConstraint = backgroundImage.heightAnchor.constraint(
            equalTo: scrollView.frameLayoutGuide.heightAnchor,
            constant: photoHeightConstraintConstant
        )

        // the photo should take the space of the screen above the footer area.
        // but should not get so small that the whole stack can't fit on a smaller screen.
        //
        // so demote the priority to one below the default conent compression resistance priority:
        photoHeightRestrictionConstraint.priority = .defaultHigh - 1
        // set its intrinsic compression resistance to be very low so it will obey most layouts:
        backgroundImage.setContentCompressionResistancePriority(
            .defaultLow,
            for: .vertical
        )

        NSLayoutConstraint.activate([
            outsetConstraint,
            photoHeightRestrictionConstraint,

            backgroundImage.bottomAnchor.constraint(equalTo: footerView.topAnchor),

            // we want no scrolling horizontally, so pin widths to scroll view
            backgroundImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundImage.widthAnchor.constraint(equalTo: view.widthAnchor),

            // ensure the content stack always is at least inside the nav bar:
            contentStackView.topAnchor.constraint(
                greaterThanOrEqualTo: contentView.layoutMarginsGuide.topAnchor,
                constant: Constants.largeSpace
            ),
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
        updatePhotoConstraints()
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

    func updatePhotoConstraints() {
        outsetConstraint.constant = outsetConstraintConstant
        photoHeightRestrictionConstraint.constant = photoHeightConstraintConstant
    }
}

extension RegisterViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updatePhotoConstraints()
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

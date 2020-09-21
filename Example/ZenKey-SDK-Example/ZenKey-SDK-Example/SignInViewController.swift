//
//  SignInViewController.swift
//  ZenKeySDK
//
//  Created by Sawyer Billings on 2/18/20.
//  Copyright © 2020 ZenKey, LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import os
import UIKit
import ZenKeySDK

class SignInViewController: UIViewController {
    //
    // ZENKEY SDK
    // Create and configure a ZenKey button with a delegate.
    // See the ZenKeyAuthorizeButtonDelegate extension below.
    //
    lazy var zenKeyButton: ZenKeyAuthorizeButton = {
        let button = ZenKeyAuthorizeButton()

        // Other scopes registered for this client_id in the Developer portal can be added here.
        let scopes: [Scope] = [.openid]
        button.scopes = scopes

        // You can later use this nonce to help validate the token response.
        button.nonce = RandomStringGenerator.generateNonceSuitableString()

        // A ZenKeyAuthorizeButtonDelegate is required.
        button.delegate = self

        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        return button
    }()

    //
    // Additional UI elements are included for demonstration only.
    //
    let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Color.Background.card
        view.layer.cornerRadius = 7.0
        view.layer.shadowOpacity = 0.06
        view.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        view.layer.shadowRadius = 9.0
        // shadowColor is set in viewWillLayoutSubviews()
        view.layer.masksToBounds = false
        return view
    }()
    
    let disclaimerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = Localized.App.demoText
        label.textColor = Color.Text.main
        label.font = UIFont.italicSystemFont(ofSize: 16.0)
        label.textAlignment = .center
        return label
    }()
    
    let logoView: UIView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.image = Asset.logo
        view.contentMode = .scaleAspectFit
        view.heightAnchor.constraint(equalToConstant: 74.0).isActive = true
        return view
    }()
    
    let backgroundView: UIView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.image = Asset.background
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    let dividerLabel: UIView = {
        let view = DividerLabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.label.text = Localized.SignIn.divider
        view.label.textColor = Color.Text.main
        view.label.font = .systemFont(ofSize: UIFont.systemFontSize)
        return view
    }()

    lazy var userIdField: UITextField = {
        let field = StyledTextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = Localized.SignIn.userPlaceholder
        field.autocorrectionType = .no
        field.delegate = self
        return field
    }()

    lazy var passwordField: UITextField = {
        let field = StyledTextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = Localized.SignIn.passwordPlaceholder
        field.isSecureTextEntry = true
        field.delegate = self
        return field
    }()

    lazy var signInButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(Localized.SignIn.buttonTitle, for: .normal)
        button.setTitleColor(Color.Text.buttonDisabled, for: .normal)
        button.backgroundColor = Color.Background.buttonDisabled
        button.layer.cornerRadius = 3.0
        button.addTarget(self, action: #selector(showFormAlert), for: .touchUpInside)
        button.titleLabel?.font = .boldSystemFont(ofSize: UIFont.systemFontSize)
        button.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        return button
    }()

    //
    // Once the user taps on the ZenKey button you should make
    // activity clear to the user using UI suitable for your app.
    // See buttonWillBeginAuthorizing() in ZenKeyAuthorizeButtonDelegate.
    //
    let activitySpinnerView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.image = Asset.spinner
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    let activityLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = Localized.SignIn.authorizing
        label.textAlignment = .center
        return label
    }()

    let activityOverlayView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Color.Background.card
        view.layer.cornerRadius = 7.0
        view.isHidden = true
        return view
    }()

    let signInService: SignInProtocol

    init(service: SignInProtocol) {
        signInService = service
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutView()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Set any cgColors here in case traitCollection changes
        cardView.layer.shadowColor = Color.shadow.cgColor
    }
}

private extension SignInViewController {
    func layoutView() {
        view.backgroundColor = Color.Background.app

        let cardStackView = UIStackView(arrangedSubviews: [
            disclaimerLabel,
            cardView,
        ])
        cardStackView.translatesAutoresizingMaskIntoConstraints = false
        cardStackView.axis = .vertical
        cardStackView.spacing = 15.0

        let signInStackView = UIStackView(arrangedSubviews: [
            logoView,
            zenKeyButton,
            dividerLabel,
            userIdField,
            passwordField,
            signInButton,
        ])
        signInStackView.translatesAutoresizingMaskIntoConstraints = false
        signInStackView.axis = .vertical
        signInStackView.spacing = 15.0
        signInStackView.setCustomSpacing(50.0, after: logoView)
        cardView.addSubview(signInStackView)

        view.addSubview(backgroundView)
        view.addSubview(scrollView)
        view.addSubview(activityOverlayView)
        scrollView.addSubview(cardStackView)
        activityOverlayView.addSubview(activitySpinnerView)
        activityOverlayView.addSubview(activityLabel)

        // view constraints
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // stack constraints
        NSLayoutConstraint.activate([
            cardStackView.leadingAnchor.constraint(greaterThanOrEqualTo: scrollView.leadingAnchor, constant: 30.0),
            cardStackView.trailingAnchor.constraint(lessThanOrEqualTo: scrollView.trailingAnchor, constant: -30.0),
            cardStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 100.0),
            cardStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -30.0),
            cardStackView.widthAnchor.constraint(lessThanOrEqualToConstant: 500.0),
            cardStackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            signInStackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 62.0),
            signInStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20.0),
            signInStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20.0),
            signInStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20.0),
            dividerLabel.widthAnchor.constraint(equalTo: signInStackView.widthAnchor),
        ])

        // loading layer constraints
        NSLayoutConstraint.activate([
            activityOverlayView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            activityOverlayView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            activityOverlayView.topAnchor.constraint(equalTo: cardView.topAnchor),
            activityOverlayView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            activitySpinnerView.heightAnchor.constraint(equalToConstant: 71.0),
            activitySpinnerView.centerXAnchor.constraint(equalTo: activityOverlayView.centerXAnchor),
            NSLayoutConstraint(
                item: activitySpinnerView, attribute: .centerY, relatedBy: .equal,
                toItem: activityOverlayView, attribute: .bottom, multiplier: 0.447, constant: 0.0),
            activityLabel.centerXAnchor.constraint(equalTo: activitySpinnerView.centerXAnchor),
            NSLayoutConstraint(
                item: activityLabel, attribute: .centerY, relatedBy: .equal,
                toItem: activityOverlayView, attribute: .bottom, multiplier: 0.688, constant: 0.0),
        ])
    }

    @objc func showFormAlert() {
        showAlert(title: Localized.SignIn.alertTitle, message: Localized.SignIn.alertText)
    }

    func startActivity() {
        activityOverlayView.isHidden = false
        // Rotation animation
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.toValue = 2.0 * CGFloat.pi
        animation.duration = 2.0
        animation.repeatCount = .infinity
        animation.isCumulative = true
        animation.isRemovedOnCompletion = false
        activitySpinnerView.layer.add(animation, forKey: "rotationAnimation")
    }

    func stopActivity() {
        activityOverlayView.isHidden = true
        activitySpinnerView.layer.removeAnimation(forKey: "rotationAnimation")
    }

    // This navigation would normally be handled in a navController or coordinator
    // but is simplified here for demo purposes
    func navigateToHomeScreen() {
        let homeVC = HomeViewController(service: signInService)
        navigationController?.setViewControllers([homeVC], animated: true)
    }

    func getErrorString(error: AuthorizationError) -> String {
        switch error.errorType {
        case .invalidRequest:
            return Localized.Error.invalidRequest
        case .requestDenied:
            return Localized.Error.requestDenied
        case .requestTimeout:
            return Localized.Error.requestTimeout
        case .serverError:
            return Localized.Error.server
        case .networkFailure:
            return Localized.Error.networkFailure
        case .configurationError:
            return Localized.Error.configuration
        case .discoveryStateError:
            return Localized.Error.discoveryState
        case .unknownError:
            return Localized.Error.unknown
        }
    }
}

extension SignInViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        showFormAlert()
        return false
    }
}

//
// ZENKEY SDK
// Create a ZenKeyAuthorizeButtonDelegate to handle the AuthorizationResult
//
extension SignInViewController: ZenKeyAuthorizeButtonDelegate {
    //
    // Called after user taps ZenKey button
    // but before the authentication flow begins.
    // Update your UI or handle any final configurations.
    //
    func buttonWillBeginAuthorizing(_ button: ZenKeyAuthorizeButton) {
        //
        // Update your viewState to clearly show activity.
        // User may see this UI briefly
        // before/after discovery and authentication.
        //
        startActivity()
    }

    //
    // Called after the user has authorized your request
    //
    func buttonDidFinish(_ button: ZenKeyAuthorizeButton, withResult result: AuthorizationResult) {
        // Handle the outcome of the ZenKey request:
        switch result {
        case .code(let authorizedResponse):
            //
            // We recommended that you send the entire AuthorizedResponse to your secure backend. An
            // AuthorizedResponse contains the parameters needed for the token request, except for your
            // ZenKey secret. It also contains parameter that you can use to validate the token response.
            //
            // This signInService.signIn function is only an example of how you might set up your endpoint.
            //
            // In account migration scenarios, where a user of your app has changed from one phone
            // carrier to another, the carrier's token endpoint response will contain one or more
            // `port_token` values for previous carriers associated with this user. Your
            // backend can use that port token to update the user in your database, and return
            // the appropriate user for this sign-in request.
            //
            // However, there are some scenarios in which the backend will be unable to associate it
            // with an existing user, and a returning user may appear to be a new user in this sign-in
            // response. (In the code example below, both a new user and a returning user that can't
            // be associated in the backend are represented with `.unlinkedUser`.) For this reason,
            // you should always give what appears to be a new user the opportunity to link to an
            // existing account in your database.
            //
            signInService.signIn(authResponse: authorizedResponse) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.passwordField.text = ""
                        self?.navigateToHomeScreen()
                    case .failure(let signInError):
                        // Stop showing loading activity
                        self?.stopActivity()

                        switch signInError {
                        case .unlinkedUser(_):
                            // Handle account linking
                            // This user has not signed-in with ZenKey previously
                            os_log("The ZenKey user is not linked in our database.")
                            return
                        default:
                            let errorDescription = signInError.errorDescription ?? "Undescribed SignInError"
                            self?.showError(errorDescription)
                            os_log("Error Signing in: %@", errorDescription)
                        }
                    }
                }
            }

        case .error(let authorizationError):
            //
            // A ZenKey/OIDC specific error has occured.
            // You should communicate to your user as appropriate for your UX.
            //
            stopActivity()
            let errorString = getErrorString(error: authorizationError)
            showError(errorString)
            os_log("Authorization Error: %@\nAlert String: %{public}@", authorizationError.localizedDescription, errorString)

        case .cancelled:
            //
            // Since the user took action to cancel the request,
            // we are not showing them an alert.
            //
            stopActivity()
            os_log("The user cancelled their request in the ZenKey application.")
        }
    }
}


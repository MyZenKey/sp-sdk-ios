//
//  LoginViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import ZenKeySDK

class LoginViewController: UIViewController {
    
    let gradientBackground: GradientView = {
        let gradientBackground = GradientView()
        gradientBackground.translatesAutoresizingMaskIntoConstraints = false
        return gradientBackground
    }()
    
    let logo: UIImageView = {
        let logo = UIImageView()
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.image = UIImage(named: "applogo_white")
        logo.contentMode = .scaleAspectFit
        return logo
    }()
    
    let idTextField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.borderStyle = .roundedRect
        field.minimumFontSize = 17
        field.placeholder = "Enter your ID"
        return field
    }()
    
    let passwordTextField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.borderStyle = .roundedRect
        field.minimumFontSize = 17
        field.placeholder = "Enter your password"
        return field
    }()
    
    let signInButton: BankAppButton = {
        let button = BankAppButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.borderWidth = 1.0
        button.borderColor = .white
        button.setTitle("SIGN IN", for: .normal)
        button.addTarget(self, action: #selector(signInButtonPressed), for: .touchUpInside)
        return button
    }()
    
    let registerButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Register", for: .normal)
        button.contentHorizontalAlignment = .right
        button.addTarget(self, action: #selector(registerButtonPressed), for: .touchUpInside)
        return button
    }()
    
    let forgotButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .left
        button.setTitle("Forgot User ID or Password", for: .normal)
        return button
    }()

    lazy var zenKeyButton: ZenKeyAuthorizeButton = {
        let button = ZenKeyAuthorizeButton()
        button.style = .light
        let scopes: [Scope] = [.openid, .authenticate, .name, .email, .postalCode, .phone]
        button.scopes = scopes
        button.translatesAutoresizingMaskIntoConstraints = false
        button.brandingDelegate = self
        button.delegate = self
        button.accessibilityIdentifier = "ZenKey Button"
        return button
    }()

    let poweredByLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    let watermarkLabel = BuildInfo.makeWatermarkLabel(lightText: true)

    lazy var inputToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [flex, doneButton]
        toolbar.sizeToFit()
        return toolbar
    }()

    private let clientSideServiceAPI: ServiceProviderAPIProtocol = BuildInfo.serviceProviderAPI()

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutView()
    }

    @objc func registerButtonPressed() {
        sharedRouter.showRegisterViewController(animated: true)
    }

    @objc func signInButtonPressed() {
        clientSideServiceAPI.login(
            withUsername: idTextField.text?.lowercased() ?? "",
            password: passwordTextField.text?.lowercased() ?? "") { [weak self] auth, error in

                guard let auth = auth, error == nil else {
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
        idTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }

    func layoutView() {
        DebugViewController.addMenu(toViewController: self)

        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let safeAreaGuide = getSafeLayoutGuide()

        view.addSubview(gradientBackground)
        view.addSubview(logo)
        view.addSubview(idTextField)
        view.addSubview(passwordTextField)
        view.addSubview(signInButton)
        view.addSubview(forgotButton)
        view.addSubview(registerButton)
        view.addSubview(zenKeyButton)
        view.addSubview(poweredByLabel)
        view.addSubview(watermarkLabel)

        gradientBackground.frame = view.frame

        idTextField.inputAccessoryView = inputToolbar
        passwordTextField.inputAccessoryView = inputToolbar

        constraints.append(logo.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor, constant: 80))
        constraints.append(logo.centerXAnchor.constraint(equalTo: safeAreaGuide.centerXAnchor))
        constraints.append(logo.heightAnchor.constraint(equalToConstant: 20))
        
        constraints.append(idTextField.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: 50))
        constraints.append(idTextField.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(idTextField.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))
        constraints.append(idTextField.heightAnchor.constraint(equalToConstant: 39))
        
        constraints.append(passwordTextField.topAnchor.constraint(equalTo: idTextField.bottomAnchor, constant: 20))
        constraints.append(passwordTextField.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(passwordTextField.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))
        constraints.append(passwordTextField.heightAnchor.constraint(equalToConstant: 39))
        
        constraints.append(signInButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20))
        constraints.append(signInButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(signInButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))
        constraints.append(signInButton.heightAnchor.constraint(equalToConstant: 39))
        
        constraints.append(forgotButton.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 5))
        constraints.append(forgotButton.leadingAnchor.constraint(equalTo: signInButton.leadingAnchor, constant: 0))
        constraints.append(forgotButton.heightAnchor.constraint(equalToConstant: 39))
        
        constraints.append(registerButton.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 5))
        constraints.append(registerButton.leadingAnchor.constraint(equalTo: forgotButton.trailingAnchor, constant: 10))
        constraints.append(registerButton.trailingAnchor.constraint(equalTo: signInButton.trailingAnchor, constant: 0))
        constraints.append(registerButton.heightAnchor.constraint(equalToConstant: 39))

        constraints.append(zenKeyButton.topAnchor.constraint(equalTo: forgotButton.bottomAnchor, constant: 20.0))
        constraints.append(zenKeyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(zenKeyButton.widthAnchor.constraint(equalTo: signInButton.widthAnchor))

        constraints.append(poweredByLabel.topAnchor.constraint(equalTo: zenKeyButton.bottomAnchor, constant: 10.0))
        constraints.append(poweredByLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(poweredByLabel.widthAnchor.constraint(equalTo: zenKeyButton.widthAnchor))

        constraints.append(watermarkLabel.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor))
        constraints.append(watermarkLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor))
        constraints.append(watermarkLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor))

        NSLayoutConstraint.activate(constraints)
    }
}

extension LoginViewController: ZenKeyAuthorizeButtonDelegate {

    func buttonWillBeginAuthorizing(_ button: ZenKeyAuthorizeButton) {
        zenKeyButton.acrValues = [BuildInfo.currentAuthMode]
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
        clientSideServiceAPI.login(
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
                            forButton button: ZenKeyBrandedButton) {
    }

    func brandingDidUpdate(_ newBranding: Branding,
                           forButton button: ZenKeyBrandedButton) {
        poweredByLabel.text = newBranding.carrierText
    }
}

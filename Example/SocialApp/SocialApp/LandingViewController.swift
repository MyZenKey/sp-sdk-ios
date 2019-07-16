//
//  LandingViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import CarriersSharedAPI

class LandingViewController: UIViewController, UITextFieldDelegate {
    
    let logo: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        img.image = UIImage(named: "icon_Socialapp")
        img.contentMode = .scaleAspectFit
        return img
    }()
    
    let nameField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor.init(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.layer.cornerRadius = 2.0
        field.layer.borderWidth = 1.0
        field.placeholder = "Email or Phone"
        return field
    }()
    
    let passwordField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor.init(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.layer.borderWidth = 1.0
        field.layer.cornerRadius = 2.0
        field.placeholder = "Password"
        return field
    }()
    
    let signUpButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Sign up", for: .normal)
        button.backgroundColor = AppTheme.themeColor
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 7.0
        button.addTarget(self, action: #selector(signUpPressed(_:)), for: .touchUpInside)
        return button
    }()
    
    let loginButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Log in", for: .normal)
        button.backgroundColor = AppTheme.themeColor
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 7.0
        return button
    }()
    
    let orLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "OR"
        label.textAlignment = .center
        return label
    }()
    
    lazy var verifyButton: ProjectVerifyAuthorizeButton = {
        let button = ProjectVerifyAuthorizeButton()
        button.delegate = self
        let scopes: [Scope] = [.authenticate, .register, .openid, .name, .email, .phone, .postalCode]
        button.scopes = scopes
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var toggleEnv: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let currentHost = BuildInfo.isQAHost ? "QA" : "Prod"
        button.setTitle("Toggle Host: current host \(currentHost)", for: .normal)
        button.addTarget(self, action: #selector(toggleHost), for: .touchUpInside)
        button.setTitleColor(.black, for: .normal)
        return button
    }()

    let illustrationPurposes: UILabel = BuildInfo.makeWatermarkLabel()
    
    let authService = AuthorizationService()
    let serviceAPI = ServiceAPI()

    /// Do any additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutView()
        updateNavigationThemeColor()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc func toggleHost(_ sender: Any) {
        BuildInfo.toggleHost()
        showAlert(
            title: "Host Updated",
            message: "The app will now exit, restart for the new host to take effect.") {
                fatalError("restarting app")
        }
    }

    @objc func signUpPressed(_: UIButton) {
        navigationController?.pushViewController(SignUpViewController(), animated: true)
    }

    func layoutView() {
        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let safeAreaGuide = getSafeLayoutGuide()
        
        view.addSubview(logo)
        view.addSubview(nameField)
        view.addSubview(passwordField)
        view.addSubview(signUpButton)
        view.addSubview(loginButton)
        view.addSubview(orLabel)
        view.addSubview(verifyButton)
        view.addSubview(illustrationPurposes)
        view.addSubview(toggleEnv)
        
        constraints.append(logo.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor, constant: 100))
        constraints.append(logo.centerXAnchor.constraint(equalTo: safeAreaGuide.centerXAnchor))
        
        constraints.append(nameField.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: 65))
        constraints.append(nameField.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(nameField.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))
        constraints.append(nameField.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(passwordField.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 15))
        constraints.append(passwordField.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(passwordField.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))
        constraints.append(passwordField.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(signUpButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 15))
        constraints.append(signUpButton.leadingAnchor.constraint(equalTo: passwordField.leadingAnchor))
        constraints.append(signUpButton.trailingAnchor.constraint(equalTo: passwordField.centerXAnchor, constant: -7.5))
        constraints.append(signUpButton.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 15))
        constraints.append(loginButton.leadingAnchor.constraint(equalTo: passwordField.centerXAnchor, constant: 7.5))
        constraints.append(loginButton.trailingAnchor.constraint(equalTo: passwordField.trailingAnchor))
        constraints.append(loginButton.heightAnchor.constraint(equalToConstant: 44))

        constraints.append(orLabel.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 25))
        constraints.append(orLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(orLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))
        
        constraints.append(verifyButton.topAnchor.constraint(equalTo: orLabel.bottomAnchor, constant: 25))
        constraints.append(verifyButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(verifyButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))

        constraints.append(toggleEnv.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(toggleEnv.topAnchor.constraint(equalTo: verifyButton.bottomAnchor, constant: 20.0))

        constraints.append(illustrationPurposes.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor))
        constraints.append(illustrationPurposes.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor))
        constraints.append(illustrationPurposes.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor))
        
        NSLayoutConstraint.activate(constraints)
        
    }
}

extension LandingViewController: ProjectVerifyAuthorizeButtonDelegate {
    
    func buttonWillBeginAuthorizing(_ button: ProjectVerifyAuthorizeButton) { }
    
    func buttonDidFinish(_ button: ProjectVerifyAuthorizeButton, withResult result: AuthorizationResult) {
        switch result {
        case .code(let authorizedResponse):
            self.authorizeUser(authorizedResponse: authorizedResponse)
        case .error:
            self.launchLoginScreen()
        case .cancelled:
            self.launchLoginScreen()
        }
    }

    func authorizeUser(authorizedResponse: AuthorizedResponse) {
        let code = authorizedResponse.code
        UserDefaults.standard.set(code, forKey: "AuthZCode")
        self.serviceAPI.login(
            withAuthCode: code,
            mcc: authorizedResponse.mcc,
            mnc: authorizedResponse.mnc,
            completionHandler: { json, error in
                guard
                    let accountToken = json?["token"],
                    let tokenString = accountToken.toString else {
                        print("error no token returned")
                        return
                }
                AccountManager.login(withToken: tokenString)
                let vc = UserInfoViewController()
                self.navigationController?.viewControllers = [vc]
        })
    }

    func launchLoginScreen() {
        // TODO: - fix this up, shouldn't be digging into app delegate but quickest refactor
        let appDelegate = UIApplication.shared.delegate! as! AppDelegate
        appDelegate.launchLoginScreen()
    }
}

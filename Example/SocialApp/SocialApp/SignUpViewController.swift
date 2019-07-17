//
//  SignUpViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import CarriersSharedAPI

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    let logo: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        img.image = UIImage(named: "icon_Socialapp")
        img.contentMode = .scaleAspectFit
        return img
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Sign up for Social App"
        label.font = UIFont.systemFont(ofSize: 24)
        label.textAlignment = .center
        return label
    }()

    let nameField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor.init(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.layer.cornerRadius = 7.0
        field.layer.borderWidth = 1.0
        field.placeholder = "Name"
        return field
    }()
    
    let emailField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor.init(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.layer.borderWidth = 1.0
        field.layer.cornerRadius = 7.0
        field.placeholder = "Email"
        return field
    }()
    
    let phoneNumberField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor.init(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.layer.cornerRadius = 7.0
        field.layer.borderWidth = 1.0
        field.placeholder = "Phone Number"
        return field
    }()
    
    let passwordField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor.init(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.layer.borderWidth = 1.0
        field.layer.cornerRadius = 7.0
        field.placeholder = "Password"
        return field
    }()
    
    let confirmPasswordField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor.init(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.layer.cornerRadius = 7.0
        field.layer.borderWidth = 1.0
        field.placeholder = "Confirm Password"
        return field
    }()
    
    let requiredLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "*All fields are required"
        label.font = UIFont.italicSystemFont(ofSize: 12)
        return label
    }()
    
    
    let signUpButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Sign up", for: .normal)
        button.backgroundColor = AppTheme.themeColor
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 7.0
        button.addTarget(self, action: #selector(signUpPressed(sender:)), for: .touchUpInside)
        return button
    }()
    
    let orLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "OR"
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    lazy var verifyButton: ProjectVerifyAuthorizeButton = {
        let button = ProjectVerifyAuthorizeButton()
        let scopes: [Scope] = [.authorize, .openid, .name, .email, .phone, .postalCode]
        button.scopes = scopes
        button.delegate = self
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let poweredByLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = "POWERED BY"
        label.font = UIFont.systemFont(ofSize: 10)
        return label
    }()
    
    let illustrationPurposes: UILabel = BuildInfo.makeWatermarkLabel()

    let serviceAPI = ServiceAPI()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        layoutView()

        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(backButtonAction(sender:)))
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
        updateNavigationThemeColor()
        // Do any additional setup after loading the view.
    }
    
   
    @objc func backButtonAction(sender : Any) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func signUpPressed(sender : Any) {
        navigationController?.pushViewController(UserInfoViewController(), animated: true)
    }

    func displayUserInfo(from json: JsonDocument) {
        if let phone = json["phone_number"].toString {
            self.phoneNumberField.text = phone
        }
        
        if let family_name = json["family_name"].toString, let given_name = json["given_name"].toString {
            self.nameField.text = "\(given_name) \(family_name)"
        }
        
        if let email = json["email"].toString {
            self.emailField.text = email
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func layoutView() {
        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let safeAreaGuide = getSafeLayoutGuide()
        
        nameField.delegate = self
        emailField.delegate = self
        phoneNumberField.delegate = self
        passwordField.delegate = self
        confirmPasswordField.delegate = self
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.centerXAnchor.constraint(equalTo: safeAreaGuide.centerXAnchor).isActive = true
        scrollView.widthAnchor.constraint(equalTo: safeAreaGuide.widthAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor).isActive = true
        
        contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true

        contentView.addSubview(titleLabel)
        contentView.addSubview(nameField)
        contentView.addSubview(emailField)
        contentView.addSubview(phoneNumberField)
        contentView.addSubview(passwordField)
        contentView.addSubview(confirmPasswordField)
        contentView.addSubview(requiredLabel)
        contentView.addSubview(signUpButton)
        contentView.addSubview(orLabel)
        contentView.addSubview(verifyButton)
        contentView.addSubview(poweredByLabel)
        contentView.addSubview(illustrationPurposes)
        
        constraints.append(titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30))
        constraints.append(titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30))
        constraints.append(titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30))
    
        constraints.append(nameField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40))
        constraints.append(nameField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30))
        constraints.append(nameField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30))
        constraints.append(nameField.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(emailField.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 15))
        constraints.append(emailField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30))
        constraints.append(emailField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30))
        constraints.append(emailField.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(phoneNumberField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 15))
        constraints.append(phoneNumberField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30))
        constraints.append(phoneNumberField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30))
        constraints.append(phoneNumberField.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(passwordField.topAnchor.constraint(equalTo: phoneNumberField.bottomAnchor, constant: 15))
        constraints.append(passwordField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30))
        constraints.append(passwordField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30))
        constraints.append(passwordField.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(confirmPasswordField.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 15))
        constraints.append(confirmPasswordField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30))
        constraints.append(confirmPasswordField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30))
        constraints.append(confirmPasswordField.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(requiredLabel.topAnchor.constraint(equalTo: confirmPasswordField.bottomAnchor, constant: 8))
        constraints.append(requiredLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30))
        constraints.append(requiredLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30))
        
        constraints.append(signUpButton.topAnchor.constraint(equalTo: requiredLabel.bottomAnchor, constant: 15))
        constraints.append(signUpButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30))
        constraints.append(signUpButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30))
        constraints.append(signUpButton.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(orLabel.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 15))
        constraints.append(orLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30))
        constraints.append(orLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30))
        
        constraints.append(verifyButton.topAnchor.constraint(equalTo: orLabel.bottomAnchor, constant: 15))
        constraints.append(verifyButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30))
        constraints.append(verifyButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30))

        constraints.append(poweredByLabel.topAnchor.constraint(equalTo: verifyButton.bottomAnchor, constant: 5))
        constraints.append(poweredByLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30))
        constraints.append(poweredByLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30))
        
        constraints.append(illustrationPurposes.topAnchor.constraint(equalTo: poweredByLabel.bottomAnchor, constant: 10))
        constraints.append(illustrationPurposes.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5))
        constraints.append(illustrationPurposes.leadingAnchor.constraint(equalTo: contentView.leadingAnchor))
        constraints.append(illustrationPurposes.trailingAnchor.constraint(equalTo: contentView.trailingAnchor))
        
        NSLayoutConstraint.activate(constraints)
    }
}

extension SignUpViewController: ProjectVerifyAuthorizeButtonDelegate {

    func buttonWillBeginAuthorizing(_ button: ProjectVerifyAuthorizeButton) { }

    func buttonDidFinish(_ button: ProjectVerifyAuthorizeButton, withResult result: AuthorizationResult) {
        switch result {
        case .code(let authorizedResponse):
            self.authorizeUser(authorizedResponse: authorizedResponse)
        case .error:
            print("error occured")
        case .cancelled:
            print("cancelled")
        }
    }

    func authorizeUser(authorizedResponse: AuthorizedResponse) {
        let code = authorizedResponse.code
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
                self.serviceAPI.getUserInfo(with: tokenString) { userInfo in
                    self.displayUserInfo(from: userInfo)
                }
        })
    }
}

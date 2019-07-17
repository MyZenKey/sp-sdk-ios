//
//  CheckoutViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import CarriersSharedAPI

class CheckoutViewController: UIViewController {
    
    let nameField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.borderStyle = .roundedRect
        field.placeholder = "Name"
        return field
    }()
    
    let emailField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.borderStyle = .roundedRect
        field.placeholder = "Email"
        return field
    }()
    
    let phoneField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.borderStyle = .roundedRect
        field.placeholder = "Phone"
        return field
    }()
    
    let cityField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.borderStyle = .roundedRect
        field.placeholder = "City, State"
        return field
    }()
    
    let zipField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.borderStyle = .roundedRect
        field.placeholder = "Phone"
        return field
    }()
    
    let requiredLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "*All fields are required"
        label.font = UIFont.italicSystemFont(ofSize: 12)
        label.textColor = .red
        return label
    }()
    
    let checkoutButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = AppTheme.themeColor
        button.setTitle("Checkout", for: .normal)
        return button
    }()
    
    lazy private(set) var verifyButton: ProjectVerifyAuthorizeButton = {
        let button = ProjectVerifyAuthorizeButton()
        let scopes: [Scope] = [.authorize, .openid, .name, .email, .address, .postalCode]
        button.scopes = scopes
        button.delegate = self
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let illustrationPurposes: UILabel = BuildInfo.makeWatermarkLabel()

    let authService = AuthorizationService()
    let serviceAPI = ServiceAPI()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        layoutView()
    }

    func requestUserInfo(token: String) {
        self.serviceAPI.getUserInfo(with: token) { userJSON in
            self.displayUserInfo(from: userJSON)
        }
    }

    func displayUserInfo(from json: JsonDocument){
        if let family_name = json["family_name"].toString, let given_name = json["given_name"].toString {
            self.nameField.text = "\(given_name) \(family_name)"
        }
        if let email = json["email"].toString {
            emailField.text = email
        }
         if let phone = json["phone_number"].toString {
            phoneField.text = phone
        }
        if let zip = json["postal_code"].toString {
            zipField.text = String(zip.prefix(5))
        }
        if let addressInfo = json["address"].toDict {
            let locality = addressInfo["locality"]
            let region = addressInfo["region"]
            cityField.text = [locality, region]
                .compactMap({ $0?.toString })
                .joined(separator: ", ")
        }
    }
    
    func layoutView() {
        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let safeAreaGuide = view.safeAreaLayoutGuide
        
        navigationItem.title = "Checkout"
        
        view.addSubview(nameField)
        view.addSubview(emailField)
        view.addSubview(phoneField)
        view.addSubview(cityField)
        view.addSubview(zipField)
        view.addSubview(requiredLabel)
        view.addSubview(checkoutButton)
        view.addSubview(verifyButton)
        view.addSubview(illustrationPurposes)
        
        constraints.append(nameField.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor, constant: 20))
        constraints.append(nameField.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 15))
        constraints.append(nameField.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -15))
        constraints.append(nameField.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(emailField.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 10))
        constraints.append(emailField.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 15))
        constraints.append(emailField.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -15))
        constraints.append(emailField.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(phoneField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 10))
        constraints.append(phoneField.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 15))
        constraints.append(phoneField.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -15))
        constraints.append(phoneField.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(cityField.topAnchor.constraint(equalTo: phoneField.bottomAnchor, constant: 10))
        constraints.append(cityField.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 15))
        constraints.append(cityField.trailingAnchor.constraint(equalTo: safeAreaGuide.centerXAnchor, constant: 25))
        constraints.append(cityField.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(zipField.centerYAnchor.constraint(equalTo: cityField.centerYAnchor))
        constraints.append(zipField.leadingAnchor.constraint(equalTo: cityField.trailingAnchor, constant: 10))
        constraints.append(zipField.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -15))
        constraints.append(zipField.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(requiredLabel.topAnchor.constraint(equalTo: cityField.bottomAnchor, constant: 10))
        constraints.append(requiredLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 15))
        constraints.append(requiredLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -15))
        
        constraints.append(checkoutButton.topAnchor.constraint(equalTo: requiredLabel.bottomAnchor, constant: 20))
        constraints.append(checkoutButton.centerXAnchor.constraint(equalTo: safeAreaGuide.centerXAnchor))
        constraints.append(checkoutButton.heightAnchor.constraint(equalToConstant: 44))
        constraints.append(checkoutButton.heightAnchor.constraint(equalToConstant: 140))
        
        constraints.append(verifyButton.topAnchor.constraint(equalTo: checkoutButton.bottomAnchor, constant: 80))
        constraints.append(verifyButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(verifyButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))

        constraints.append(illustrationPurposes.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor, constant: -5))
        constraints.append(illustrationPurposes.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor))
        constraints.append(illustrationPurposes.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor))

        NSLayoutConstraint.activate(constraints)
        
    }
    
}

extension CheckoutViewController: ProjectVerifyAuthorizeButtonDelegate {

    func buttonWillBeginAuthorizing(_ button: ProjectVerifyAuthorizeButton) { }

    func buttonDidFinish(_ button: ProjectVerifyAuthorizeButton, withResult result: AuthorizationResult) {
        // handle the result of the authorization call
        switch result {
        case .code(let authorizedResponse):
            self.authorizeUser(authorizedResponse: authorizedResponse)
        case .error(let error):
            self.completeFlow(withError: error)
        case .cancelled:
            self.cancelFlow()
        }
    }

    func authorizeUser(authorizedResponse: AuthorizedResponse) {
        let code = authorizedResponse.code
        serviceAPI.login(
            withAuthCode: code,
            mcc: authorizedResponse.mcc,
            mnc: authorizedResponse.mnc,
            completionHandler: { json, error in
                guard
                    let accountToken = json?["token"],
                    let tokenString = accountToken.toString else {
                        self.showAlert(title: "Error", message: "Error logging in.", onDismiss: nil)
                        return
                }

                self.requestUserInfo(token: tokenString)
        })
    }
}

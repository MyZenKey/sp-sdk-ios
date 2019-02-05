//
//  LoginViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

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
        button.addTarget(self, action: #selector(signInWithVerifyTouched(_:)), for: .touchUpInside)
        return button
    }()
    
    let registerButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Register", for: .normal)
        button.contentHorizontalAlignment = .right
        button.addTarget(self, action: #selector(signInWithVerifyTouched(_:)), for: .touchUpInside)
        return button
    }()
    
    let forgotButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .left
        button.setTitle("Forgot User ID or Password", for: .normal)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        layoutView()
        idTextField.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        idTextField.becomeFirstResponder()
    }
    
    @objc func loginButtonTouched(_ sender: Any) {
        // TODO: see UX section 2.3.1 in design doc
        // Does SP have this ID associated with CCID (Verify)?
        //   No - show Enable Verify screen, then go to sub-flow 2.0.3 in Verify
        //   Yes - go directly to sub-flow 2.0.3 in Verify
        self.navigationController?.pushViewController(EnableVerifyViewController(), animated: true)
    }
    
    @objc func signInWithVerifyTouched(_ sender: Any) {
        // TODO: see UX section 2.3.1 in design doc
        // Does SP have this ID associated with CCID (Verify)?
        //   No - show Enable Verify screen, then go to sub-flow 2.0.3 in Verify
        //   Yes - go directly to sub-flow 2.0.3 in Verify
        self.navigationController?.pushViewController(EnableVerifyViewController(), animated: true)
    }
    
    func layoutView() {
        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let safeAreaGuide = view.safeAreaLayoutGuide
        
        view.addSubview(gradientBackground)
        view.addSubview(logo)
        view.addSubview(idTextField)
        view.addSubview(passwordTextField)
        view.addSubview(signInButton)
        view.addSubview(forgotButton)
        view.addSubview(registerButton)
        
        gradientBackground.frame = view.frame
        
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
        
        NSLayoutConstraint.activate(constraints)
        
    }

}

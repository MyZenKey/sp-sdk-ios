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
        button.titleLabel?.textAlignment = .right
        button.addTarget(self, action: #selector(signInWithVerifyTouched(_:)), for: .touchUpInside)
        return button
    }()
    
    let forgotButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Forgot User ID or Password", for: .normal)
        button.titleLabel?.textAlignment = .left
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
        let marginGuide = view.safeAreaLayoutGuide
        
        view.addSubview(gradientBackground)
        view.addSubview(logo)
        view.addSubview(idTextField)
        view.addSubview(passwordTextField)
        view.addSubview(signInButton)
        view.addSubview(forgotButton)
        view.addSubview(registerButton)
        
        gradientBackground.frame = view.frame
        
        constraints.append(NSLayoutConstraint(item: logo,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: 80))
        constraints.append(NSLayoutConstraint(item: logo,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .centerX,
                                              multiplier: 1,
                                              constant: 0))
        logo.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        constraints.append(NSLayoutConstraint(item: idTextField,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: logo,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 50))
        constraints.append(NSLayoutConstraint(item: idTextField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 30))
        constraints.append(NSLayoutConstraint(item: idTextField,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: -30))
        idTextField.heightAnchor.constraint(equalToConstant: 39).isActive = true
        
        constraints.append(NSLayoutConstraint(item: passwordTextField,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: idTextField,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 20))
        constraints.append(NSLayoutConstraint(item: passwordTextField,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 30))
        constraints.append(NSLayoutConstraint(item: passwordTextField,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: -30))
        passwordTextField.heightAnchor.constraint(equalToConstant: 39).isActive = true
        
        constraints.append(NSLayoutConstraint(item: signInButton,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: passwordTextField,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 20))
        constraints.append(NSLayoutConstraint(item: signInButton,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 30))
        constraints.append(NSLayoutConstraint(item: signInButton,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: -30))
        signInButton.heightAnchor.constraint(equalToConstant: 39).isActive = true
        
        constraints.append(NSLayoutConstraint(item: forgotButton,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: signInButton,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 5))
        constraints.append(NSLayoutConstraint(item: forgotButton,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: signInButton,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0))
        constraints.append(NSLayoutConstraint(item: forgotButton,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: signInButton,
                                              attribute: .centerX,
                                              multiplier: 1,
                                              constant: 0))
        forgotButton.heightAnchor.constraint(equalToConstant: 39).isActive = true
        
        constraints.append(NSLayoutConstraint(item: registerButton,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: signInButton,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 5))
        constraints.append(NSLayoutConstraint(item: registerButton,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: signInButton,
                                              attribute: .centerX,
                                              multiplier: 1,
                                              constant: 0))
        constraints.append(NSLayoutConstraint(item: registerButton,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: signInButton,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 0))
        registerButton.heightAnchor.constraint(equalToConstant: 39).isActive = true
        
        NSLayoutConstraint.activate(constraints)
        
    }

}

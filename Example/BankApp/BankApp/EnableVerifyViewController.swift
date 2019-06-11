//
//  EnableVerifyViewController.swift
//  BankApp
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import CarriersSharedAPI

class EnableVerifyViewController: UIViewController {

    let gradientView: GradientView = {
        let gradientView = GradientView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        return gradientView
    }()
    
    let logo: UIImageView = {
        let logo = UIImageView()
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.image = UIImage(named: "applogo_white")
        logo.contentMode = .scaleAspectFit
        return logo
    }()
    
    let enableButton: BankAppButton = {
        let button = BankAppButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("YES", for: .normal)
        button.addTarget(self, action: #selector(enableVerify(_:)), for: .touchUpInside)
        button.backgroundColor = UIColor(red: 0.36, green: 0.56, blue: 0.93, alpha: 1.0)
        return button
    }()
    
    let cancelButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("No, thanks", for: .normal)
        button.addTarget(self, action: #selector(cancelVerify(_:)), for: .touchUpInside)
        button.setTitleColor(UIColor(red: 0.36, green: 0.56, blue: 0.93, alpha: 1.0), for: .normal)

        return button
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let text = "We now support\nProject Verify"
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttributes([NSAttributedStringKey.font :  UIFont.italicSystemFont(ofSize: 38), NSAttributedStringKey.foregroundColor:UIColor.black], range: (text as NSString).range(of: "Project Verify"))
        label.attributedText = attributedString
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let text = "Would you like to use Project Verify to approve future Bank App logins?"
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttributes([NSAttributedStringKey.font :  UIFont.italicSystemFont(ofSize: 18), NSAttributedStringKey.foregroundColor:UIColor.black], range: (text as NSString).range(of: "Project Verify"))
        label.attributedText = attributedString
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    let illustrationPurposes: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "For illustration purposes only"
        label.textAlignment = .center
        return label
    }()

    let authService = AuthorizationService()
    let serviceAPI = ServiceAPI()

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func cancelVerify(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func enableVerify(_ sender: Any) {
        let scopes: [Scope] = [.openid, .profile, .email]
        authService.authorize(
            scopes: scopes,
            fromViewController: self) { result in
                // handle the result of the authorization call
                switch result {
                case .code(let authorizedResponse):
                    self.authorizeUser(authorizedResponse: authorizedResponse)
                case .error:
                    self.launchLoginScreen()
                case .cancelled:
                    self.launchLoginScreen()
                }
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
                self.launchHomeScreen()
        })
    }

    func launchLoginScreen() {
        // TODO: - fix this up, shouldn't be digging into app delegate but quickest refactor
        let appDelegate = UIApplication.shared.delegate! as! AppDelegate
        appDelegate.launchLoginScreen()
    }

    func launchHomeScreen() {
        // TODO: - fix this up, shouldn't be digging into app delegate but quickest refactor
        let appDelegate = UIApplication.shared.delegate! as! AppDelegate
        appDelegate.launchHomeScreen()
    }

    func layoutView() {
        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let safeAreaGuide: UILayoutGuide
        if #available(iOS 11.0, *) {
            safeAreaGuide = view.safeAreaLayoutGuide
        } else {
            // Fallback on earlier versions
            safeAreaGuide = view.layoutMarginsGuide
        }
        
        view.addSubview(gradientView)
        view.addSubview(logo)
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(enableButton)
        view.addSubview(cancelButton)
        view.addSubview(illustrationPurposes)
        
        constraints.append(gradientView.topAnchor.constraint(equalTo: view.topAnchor))
        constraints.append(gradientView.widthAnchor.constraint(equalTo: view.widthAnchor))
        constraints.append(gradientView.heightAnchor.constraint(equalToConstant: 70))
        
        constraints.append(logo.centerYAnchor.constraint(equalTo: gradientView.centerYAnchor))
        constraints.append(logo.centerXAnchor.constraint(equalTo: safeAreaGuide.centerXAnchor))
        constraints.append(logo.heightAnchor.constraint(equalToConstant: 60))
        
        constraints.append(titleLabel.topAnchor.constraint(equalTo: gradientView.bottomAnchor, constant: 100))
        constraints.append(titleLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(titleLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))
        
        constraints.append(descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20))
        constraints.append(descriptionLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(descriptionLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))
        
        constraints.append(cancelButton.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor, constant: -25))
        constraints.append(cancelButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48))
        constraints.append(cancelButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48))
        constraints.append(cancelButton.heightAnchor.constraint(equalToConstant: 48))
        
        constraints.append(enableButton.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -25))
        constraints.append(enableButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48))
        constraints.append(enableButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48))
        constraints.append(enableButton.heightAnchor.constraint(equalToConstant: 48))
        
        constraints.append(illustrationPurposes.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor))
        constraints.append(illustrationPurposes.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor))
        constraints.append(illustrationPurposes.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor))
        
        NSLayoutConstraint.activate(constraints)
        
    }
}

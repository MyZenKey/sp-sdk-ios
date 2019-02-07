//
//  DebugViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import MapKit

class DebugViewController: UIViewController {
    
    let tokenLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.text = "Token response:"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        return label
    }()
    
    let tokenValue: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.text = "Not received yet."
        return label
    }()
    
    let userInfoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.text = "UserInfo response:"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        return label
    }()
    
    let userInfoValue: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.text = "Not received yet."
        return label
    }()
    
    let AuthZCodeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.text = "AuthZ response:"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        return label
    }()
    
    let AuthZCodeValue: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.text = "Not received yet."
        return label
    }()
    
    let doneButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        button.backgroundColor = AppTheme.themeColor
        button.setTitle("Done", for: .normal)
        button.addTarget(self, action: #selector(done), for: .touchUpInside)
        return button
    }()
    
    let illustrationPurposes: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "For illustration purposes only"
        label.textAlignment = .center
        return label
    }()
    
    struct Info {
        let token: String?
        let userInfo: String?
        let code: String?
    }
    
    var debug: Info?
    
    func finalInit(with debug: Info) {
        self.debug = debug
    }
    
    /// Do any additional setup after loading the view.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        layoutView()
        
        if let debug = debug {
            if let token = debug.token {
                tokenValue.text = token
                print(token)
            }
            if let userInfo = debug.userInfo {
                userInfoValue.text = userInfo
                print(userInfo)
            }
            if let authZcode = debug.code {
                AuthZCodeValue.text = authZcode
                print(authZcode)
            }
        }
    }
    
    @IBAction func done() {
        dismiss(animated: true, completion: nil)
    }
    
    func layoutView() {
        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let safeAreaGuide = view.safeAreaLayoutGuide
        
        navigationController?.isNavigationBarHidden = true
        
        view.addSubview(tokenLabel)
        view.addSubview(tokenValue)
        view.addSubview(userInfoLabel)
        view.addSubview(userInfoValue)
        view.addSubview(AuthZCodeLabel)
        view.addSubview(AuthZCodeValue)
        view.addSubview(doneButton)
        view.addSubview(illustrationPurposes)
        
        constraints.append(tokenLabel.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor, constant: 5))
        constraints.append(tokenLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 5))
        
        constraints.append(tokenValue.topAnchor.constraint(equalTo: tokenLabel.bottomAnchor, constant: 5))
        constraints.append(tokenValue.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 5))
        
        constraints.append(userInfoLabel.topAnchor.constraint(equalTo: tokenValue.bottomAnchor, constant: 5))
        constraints.append(userInfoLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 5))
        
        constraints.append(userInfoValue.topAnchor.constraint(equalTo: userInfoLabel.bottomAnchor, constant: 5))
        constraints.append(userInfoValue.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 5))
        
        constraints.append(AuthZCodeLabel.topAnchor.constraint(equalTo: userInfoValue.bottomAnchor, constant: 5))
        constraints.append(AuthZCodeLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 5))
        
        constraints.append(AuthZCodeValue.topAnchor.constraint(equalTo: AuthZCodeLabel.bottomAnchor, constant: 5))
        constraints.append(AuthZCodeValue.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 5))
        
        constraints.append(doneButton.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor, constant: -25))
        constraints.append(doneButton.centerXAnchor.constraint(equalTo: safeAreaGuide.centerXAnchor))
        constraints.append(doneButton.heightAnchor.constraint(equalToConstant: 44))
        constraints.append(doneButton.widthAnchor.constraint(equalToConstant: 100))
        
        constraints.append(illustrationPurposes.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor))
        constraints.append(illustrationPurposes.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor))
        constraints.append(illustrationPurposes.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor))
        
        NSLayoutConstraint.activate(constraints)
    }
}

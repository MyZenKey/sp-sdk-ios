//
//  HomeViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

class HomeViewController: UIViewController {
    
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
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Welcome!"
        label.font = UIFont.systemFont(ofSize: 24)
        label.textAlignment = .center
        return label
    }()
    
    let sendMoneyButton: BankAppButton = {
        let button = BankAppButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Send Money", for: .normal)
        button.addTarget(self, action: #selector(sendMoneyTouched(_:)), for: .touchUpInside)
        button.backgroundColor = UIColor(red: 0.36, green: 0.56, blue: 0.93, alpha: 1.0)
        return button
    }()
    
    let logoutButton: BankAppButton = {
        let button = BankAppButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Logout", for: .normal)
        button.addTarget(self, action: #selector(logoutButtonTouched(_:)), for: .touchUpInside)
        button.backgroundColor = UIColor(red: 0.36, green: 0.56, blue: 0.93, alpha: 1.0)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        layoutView()
    }

    @objc func logoutButtonTouched(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func sendMoneyTouched(_ sender: Any) {
        navigationController?.pushViewController(ApproveViewController(), animated: true)
    }
    
    func layoutView() {
        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let safeAreaGuide = view.safeAreaLayoutGuide
        
        
        view.addSubview(gradientView)
        view.addSubview(logo)
        view.addSubview(titleLabel)
        view.addSubview(sendMoneyButton)
        view.addSubview(logoutButton)
        
        constraints.append(NSLayoutConstraint(item: gradientView,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: 0))
        constraints.append(NSLayoutConstraint(item: gradientView,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .width,
                                              multiplier: 1,
                                              constant: 0))
        constraints.append(gradientView.heightAnchor.constraint(equalToConstant: 70))
        
        constraints.append(NSLayoutConstraint(item: logo,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: gradientView,
                                              attribute: .centerY,
                                              multiplier: 1,
                                              constant: 0))
        constraints.append(NSLayoutConstraint(item: logo,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: safeAreaGuide,
                                              attribute: .centerX,
                                              multiplier: 1,
                                              constant: 0))
        constraints.append(logo.heightAnchor.constraint(equalToConstant: 60))
        
        constraints.append(NSLayoutConstraint(item: titleLabel,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: gradientView,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 100))
        constraints.append(NSLayoutConstraint(item: titleLabel,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: safeAreaGuide,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 30))
        constraints.append(NSLayoutConstraint(item: titleLabel,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: safeAreaGuide,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: -30))
        
        
        constraints.append(NSLayoutConstraint(item: sendMoneyButton,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: titleLabel,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 20))
        constraints.append(NSLayoutConstraint(item: sendMoneyButton,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: safeAreaGuide,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 48))
        constraints.append(NSLayoutConstraint(item: sendMoneyButton,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: safeAreaGuide,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: -48))
        constraints.append(sendMoneyButton.heightAnchor.constraint(equalToConstant: 48))
        
        constraints.append(NSLayoutConstraint(item: logoutButton,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: safeAreaGuide,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: -50))
        constraints.append(NSLayoutConstraint(item: logoutButton,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: safeAreaGuide,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 48))
        constraints.append(NSLayoutConstraint(item: logoutButton,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: safeAreaGuide,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: -48))
        constraints.append(logoutButton.heightAnchor.constraint(equalToConstant: 48))
        
        NSLayoutConstraint.activate(constraints)
        
    }

}

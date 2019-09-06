//
//  HomeViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

class HomeViewController: BankAppViewController {

    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Welcome!"
        label.font = UIFont.systemFont(ofSize: 24)
        label.textAlignment = .center
        return label
    }()

    let userInfoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
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

    private var userInfo: UserInfo? {
        didSet {
            updateUserInfo()
        }
    }

    private var serviceAPI: ServiceProviderAPIProtocol = BuildInfo.serviceProviderAPI()

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUserInfoIfNeeded()
    }

    @objc func logoutButtonTouched(_ sender: Any) {
        (UIApplication.shared.delegate as? AppDelegate)?.logout()
    }
    
    @objc func sendMoneyTouched(_ sender: Any) {
        sharedRouter.showApproveViewController(animated: true)
    }
    
    func layoutView() {
        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let safeAreaGuide = getSafeLayoutGuide()
        
        view.addSubview(titleLabel)
        view.addSubview(userInfoLabel)
        view.addSubview(sendMoneyButton)
        view.addSubview(logoutButton)
        
        constraints.append(titleLabel.topAnchor.constraint(equalTo: gradientView.bottomAnchor, constant: 100))
        constraints.append(titleLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(titleLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))

        constraints.append(userInfoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20))
        constraints.append(userInfoLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor))
        constraints.append(userInfoLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor))

        constraints.append(sendMoneyButton.topAnchor.constraint(equalTo: userInfoLabel.bottomAnchor, constant: 20))
        constraints.append(sendMoneyButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48))
        constraints.append(sendMoneyButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48))
        constraints.append(sendMoneyButton.heightAnchor.constraint(equalToConstant: 48))

        constraints.append(logoutButton.bottomAnchor.constraint(equalTo: illustrationPurposes.topAnchor, constant: -50))
        constraints.append(logoutButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48))
        constraints.append(logoutButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48))
        constraints.append(logoutButton.heightAnchor.constraint(equalToConstant: 48))

        NSLayoutConstraint.activate(constraints)
    }
}

// MARK: - User Info

private extension HomeViewController {
    func fetchUserInfoIfNeeded() {
        serviceAPI.getUserInfo() { [weak self] userInfo, error in

            guard error == nil else {
                self?.handleNetworkError(error: error!)
                return
            }

            self?.userInfo = userInfo
        }
    }
    
    func updateUserInfo() {
        guard let userInfo = userInfo else {
            userInfoLabel.text = nil
            return
        }

        userInfoLabel.text = """
        user: \(userInfo.username)
        name: \(userInfo.name ?? "{name}")
        birthdate: \(userInfo.birthdate ?? "{birthdate}")
        email: \(userInfo.email ?? "{email}") | zip: \(userInfo.postalCode ?? "{postal code}")
        """
    }
}

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

    let viewHistoryButton: BankAppButton = {
        let button = BankAppButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("View History", for: .normal)
        button.addTarget(self, action: #selector(viewHistoryTouched(_:)), for: .touchUpInside)
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

    @objc func viewHistoryTouched(_ sender: Any) {
        sharedRouter.showHistoryScreen(animated: true)
    }

    @objc func sendMoneyTouched(_ sender: Any) {
        sharedRouter.showApproveViewController(animated: true)
    }

    func layoutView() {
        view.backgroundColor = .white
        let safeAreaGuide = getSafeLayoutGuide()
        
        view.addSubview(titleLabel)
        view.addSubview(userInfoLabel)
        view.addSubview(sendMoneyButton)
        view.addSubview(viewHistoryButton)
        view.addSubview(logoutButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: gradientView.bottomAnchor, constant: 100),
            titleLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30),
            titleLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30),

            userInfoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            userInfoLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            userInfoLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            sendMoneyButton.topAnchor.constraint(equalTo: userInfoLabel.bottomAnchor, constant: 20),
            sendMoneyButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48),
            sendMoneyButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48),
            sendMoneyButton.heightAnchor.constraint(equalToConstant: 48),

            viewHistoryButton.topAnchor.constraint(equalTo: sendMoneyButton.bottomAnchor, constant: 20),
            viewHistoryButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48),
            viewHistoryButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48),
            viewHistoryButton.heightAnchor.constraint(equalToConstant: 48),

            logoutButton.bottomAnchor.constraint(equalTo: illustrationPurposes.topAnchor, constant: -50),
            logoutButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48),
            logoutButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48),
            logoutButton.heightAnchor.constraint(equalToConstant: 48),
            ])
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
        name: \(userInfo.name ?? "{name}") | phone: \(userInfo.phone ?? "{phone}")
        email: \(userInfo.email ?? "{email}") | zip: \(userInfo.postalCode ?? "{postal code}")
        """
    }
}

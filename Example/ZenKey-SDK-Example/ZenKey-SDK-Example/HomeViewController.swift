//
//  HomeViewController.swift
//  ZenKeySDK
//
//  Created by Sawyer Billings on 2/18/20.
//  Copyright © 2020 ZenKey, LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import ZenKeySDK
import os

class HomeViewController: UIViewController {

    let disclaimerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = Localized.App.demoText
        label.textColor = Color.Text.main
        label.font = .italicSystemFont(ofSize: 16.0)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    let usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Color.Text.secondary
        label.font = .systemFont(ofSize: 35.0)
        label.numberOfLines = 0
        return label
    }()
    
    let activitiesButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = Color.Background.button
        let height: CGFloat = 60.0
        button.heightAnchor.constraint(equalToConstant: height).isActive = true
        button.layer.cornerRadius = height / 2.0
        button.titleLabel?.font = .systemFont(ofSize: 16.0, weight: .bold)
        button.setTitle(Localized.Home.activities, for: .normal)
        button.addTarget(self, action: #selector(showDemoMessage), for: .touchUpInside)
        return button
    }()
    
    lazy var volunteerButtonView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.image = Asset.volunteer
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showDemoMessage)))
        return view
    }()

    lazy var outdoorsButtonView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.image = Asset.outdoors
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showDemoMessage)))
        return view
    }()

    lazy var fitnessButtonView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.image = Asset.fitness
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showDemoMessage)))
        return view
    }()

    // Shows activity while fetching user info or signing out.
    let activityIndicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView()
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.color = Color.Text.main
        return indicatorView
    }()

    let signInService: SignInProtocol

    init(service: SignInProtocol) {
        signInService = service
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicatorView.startAnimating()
        // Sign in success only returned a token; now we fetch user data
        signInService.getUser { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self?.displayUserInfo(user)
                case .failure(let error):
                    self?.handleUserResponseError(error)
                }
            }
        }

        styleNavBar()
        layoutView()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillAppear(animated)
    }

}

private extension HomeViewController {
    func styleNavBar() {
        self.navigationController?.navigationBar.barTintColor = Color.Background.app
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        let signOutButton = UIBarButtonItem.init(title: Localized.Home.signOut,
                                                 style: .done,
                                                 target: self,
                                                 action: #selector(signOutPressed))
        signOutButton.tintColor = Color.Text.secondary
        self.navigationItem.rightBarButtonItem = signOutButton
        
        let titleView = UIView()
        titleView.translatesAutoresizingMaskIntoConstraints = false
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = Asset.logomark
        imageView.contentMode = .scaleAspectFit
        titleView.addSubview(imageView)
        self.navigationItem.titleView = titleView

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: titleView.topAnchor, constant: 2.0),
            imageView.bottomAnchor.constraint(equalTo: titleView.bottomAnchor, constant: -7.0),
            imageView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor),
        ])
    }
    
    func layoutView() {
        view.backgroundColor = Color.Background.home
        
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        let homeStack = UIStackView(arrangedSubviews: [
            disclaimerLabel,
            usernameLabel,
            activitiesButton,
            volunteerButtonView,
            outdoorsButtonView,
            fitnessButtonView,
        ])
        homeStack.translatesAutoresizingMaskIntoConstraints = false
        homeStack.axis = .vertical
        homeStack.spacing = 10.0
        homeStack.setCustomSpacing(30.0, after: disclaimerLabel)
        homeStack.setCustomSpacing(25.0, after: usernameLabel)
        homeStack.setCustomSpacing(20.0, after: activitiesButton)

        scrollView.addSubview(homeStack)
        view.addSubview(scrollView)
        view.addSubview(activityIndicatorView)
        
        // Lowering priority from required to high so that margins can expand
        // when the screen is wider than the max width set below
        let stackLeadingConstraint = homeStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 33.0)
        stackLeadingConstraint.priority = .defaultHigh
        stackLeadingConstraint.isActive = true
        let stackTrailingConstraint = homeStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -33.0)
        stackTrailingConstraint.priority = .defaultHigh
        stackTrailingConstraint.isActive = true

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            homeStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 40.0),
            homeStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -33.0),
            homeStack.widthAnchor.constraint(lessThanOrEqualToConstant: 500.0),
            homeStack.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

    }

    // This navigation would normally be handled in a navController or coordinator
    // but is simplified here for demo purposes
    func navigateToSignInScreen() {
        let signInVC = SignInViewController(service: signInService)
        navigationController?.setViewControllers([signInVC], animated: true)
    }

    @objc func signOutPressed() {
        // sign out steps
        activityIndicatorView.startAnimating()
        signInService.signOut() { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicatorView.stopAnimating()
                switch result {
                case .success:
                    // signed out
                    os_log("Successfully signed out")
                    self?.navigateToSignInScreen()
                case .failure(let error):
                    // failed to sign out
                    self?.handleSignOutResponseError(error)
                }
            }
        }
    }
    
    @objc func showDemoMessage() {
        showAlert(title: Localized.Home.alertTitle, message: Localized.Home.alertText)
    }

    func displayUserInfo(_ user: User) {
        activityIndicatorView.stopAnimating()
        
        usernameLabel.text = Localized.Home.welcome(user.username ?? "")
    }

    func handleUserResponseError(_ error: UserResponseError) {
        activityIndicatorView.stopAnimating()

        let errorDescription = error.errorDescription ?? "Undescribed UserResponseError"
        showError(errorDescription)
        os_log("Error getting user info: %@", errorDescription)
    }

    func handleSignOutResponseError(_ error: SignOutError) {
        let errorDescription = error.errorDescription ?? "Undescribed SignOutError"
        showError(errorDescription)
        os_log("Error signing out: %@", errorDescription)
    }
}

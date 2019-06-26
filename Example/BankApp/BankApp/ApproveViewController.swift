//
//  ApproveViewController.swift
//  BankApp
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import CarriersSharedAPI

class ApproveViewController: UIViewController {
    
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
    
    let promptLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Would you like to transfer $100.00 to nmel1234?"
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    let yesButton: BankAppButton = {
        let button = BankAppButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Yes", for: .normal)
        button.addTarget(self, action: #selector(initiateTransfer(_:)), for: .touchUpInside)
        button.backgroundColor = AppTheme.primaryBlue
        return button
    }()
    
    let cancelButton: BankAppButton = {
        let button = BankAppButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Cancel", for: .normal)
        button.addTarget(self, action: #selector(cancelTransaction(_:)), for: .touchUpInside)
        button.backgroundColor = AppTheme.primaryBlue
        return button
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

    let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.stopAnimating()
        return indicator
    }()

    private var notification: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        layoutView()
    }

    @objc func cancelTransaction(_ sender: Any) {
        if authService.isAuthorizing {
            authService.cancel()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc func initiateTransfer(_ sender: Any) {
        showActivityIndicator()
        yesButton.isEnabled = false

        let scopes: [Scope] = [.openid, .authorize]
        authService.authorize(
            scopes: scopes,
            fromViewController: self,
            acrValues: [.aal2]) { [weak self] result in
                defer {
                    self?.hideActivityIndicator()
                    self?.yesButton.isEnabled = true
                }

                switch result {
                case .code(let response):
                    self?.completeFlow(withAuthChode: response.code,
                                       mcc: response.mcc,
                                       mnc: response.mnc)

                case .error(let error):
                    self?.completeFlow(withError: error)

                case .cancelled:
                    self?.cancelFlow()
                }
        }
    }

    func completeFlow(withAuthChode code: String, mcc: String, mnc: String) {
        serviceAPI.completeTransfer(
            withAuthCode: code,
            mcc: mcc,
            mnc: mnc,
            completionHandler: { _ in
                self.showAlert(title: "Success", message: "Your transfer has succeeded")
        })
    }

    func showActivityIndicator() {
        activityIndicator.startAnimating()
    }

    func hideActivityIndicator() {
        activityIndicator.stopAnimating()
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
        view.addSubview(promptLabel)
        view.addSubview(yesButton)
        view.addSubview(cancelButton)
        view.addSubview(illustrationPurposes)
        view.addSubview(activityIndicator)

        constraints.append(gradientView.topAnchor.constraint(equalTo: view.topAnchor))
        constraints.append(gradientView.widthAnchor.constraint(equalTo: view.widthAnchor))
        constraints.append(gradientView.heightAnchor.constraint(equalToConstant: 70))
        
        constraints.append(logo.centerYAnchor.constraint(equalTo: gradientView.centerYAnchor))
        constraints.append(logo.centerXAnchor.constraint(equalTo: safeAreaGuide.centerXAnchor))
        constraints.append(logo.heightAnchor.constraint(equalToConstant: 60))
        
        constraints.append(promptLabel.topAnchor.constraint(equalTo: gradientView.bottomAnchor, constant: 100))
        constraints.append(promptLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(promptLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))
        
        constraints.append(cancelButton.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor, constant: -30))
        constraints.append(cancelButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48))
        constraints.append(cancelButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48))
        constraints.append(cancelButton.heightAnchor.constraint(equalToConstant: 48))
        
        constraints.append(yesButton.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -10))
        constraints.append(yesButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48))
        constraints.append(yesButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48))
        constraints.append(yesButton.heightAnchor.constraint(equalToConstant: 48))
        
        constraints.append(illustrationPurposes.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor))
        constraints.append(illustrationPurposes.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor))
        constraints.append(illustrationPurposes.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor))

        constraints.append(activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor))

        NSLayoutConstraint.activate(constraints)
    }
}

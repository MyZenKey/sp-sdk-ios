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

    let serviceAPI = ServiceAPI()

    let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.stopAnimating()
        return indicator
    }()

    lazy var projectVerifyButton: ProjectVerifyAuthorizeButton = {
        let button = ProjectVerifyAuthorizeButton()
        button.style = .dark
        let scopes: [Scope] = [.authorize]
        button.scopes = scopes
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self
        button.acrValues = [.aal2]
        return button
    }()

    private var notification: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        layoutView()
    }

    @objc func cancelTransaction(_ sender: Any) {
        if projectVerifyButton.isAuthorizing {
            projectVerifyButton.cancel()
        } else {
            navigationController?.popViewController(animated: true)
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
        view.addSubview(projectVerifyButton)
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
        
        constraints.append(projectVerifyButton.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -10))
        constraints.append(projectVerifyButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 48))
        constraints.append(projectVerifyButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -48))

        constraints.append(illustrationPurposes.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor))
        constraints.append(illustrationPurposes.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor))
        constraints.append(illustrationPurposes.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor))

        constraints.append(activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor))

        NSLayoutConstraint.activate(constraints)
    }
}

extension ApproveViewController: ProjectVerifyAuthorizeButtonDelegate {

    func buttonWillBeginAuthorizing(_ button: ProjectVerifyAuthorizeButton) {
        showActivityIndicator()
        projectVerifyButton.isEnabled = false
    }

    func buttonDidFinish(_ button: ProjectVerifyAuthorizeButton, withResult result: AuthorizationResult) {
        defer {
            hideActivityIndicator()
            projectVerifyButton.isEnabled = true
        }

        switch result {
        case .code(let response):
            completeFlow(withAuthChode: response.code,
                         mcc: response.mcc,
                         mnc: response.mnc)

        case .error(let error):
            completeFlow(withError: error)

        case .cancelled:
            cancelFlow()
        }
    }
}

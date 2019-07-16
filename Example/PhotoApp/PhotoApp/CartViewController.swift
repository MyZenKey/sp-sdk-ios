//
//  CartViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

class CartViewController: UIViewController {
    
    let itemLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Cart subtotal (1 item): $5.90"
        return label
    }()
    
    let checkoutButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = AppTheme.themeColor
        button.setTitle("Checkout", for: .normal)
        button.addTarget(self, action: #selector(checkoutPressed(sender:)), for: .touchUpInside)
        return button
    }()

    lazy var toggleEnv: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let currentHost = BuildInfo.isQAHost ? "QA" : "Prod"
        button.setTitle("Toggle Host: current host \(currentHost)", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(toggleHost), for: .touchUpInside)
        return button
    }()
    
    let illustrationPurposes: UILabel = BuildInfo.makeWatermarkLabel()

    /// Do any additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        layoutView()
    }
    
    @objc func checkoutPressed(sender: UIButton) {
        navigationController?.pushViewController(CheckoutViewController(), animated: true)
    }

    @objc func toggleHost(_ sender: Any) {
        BuildInfo.toggleHost()
        showAlert(
            title: "Host Updated",
            message: "The app will now exit, restart for the new host to take effect.") {
                fatalError("restarting app")
        }
    }

    func layoutView() {
        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let safeAreaGuide = view.safeAreaLayoutGuide
        
        navigationItem.title = "ShoppingCart"
        
        view.addSubview(itemLabel)
        view.addSubview(checkoutButton)
        view.addSubview(toggleEnv)
        view.addSubview(illustrationPurposes)
        
        constraints.append(itemLabel.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor, constant: 10))
        constraints.append(itemLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 10))
        constraints.append(itemLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -10))
        
        constraints.append(checkoutButton.bottomAnchor.constraint(equalTo: toggleEnv.topAnchor, constant: -40))
        constraints.append(checkoutButton.centerXAnchor.constraint(equalTo: safeAreaGuide.centerXAnchor))
        constraints.append(checkoutButton.heightAnchor.constraint(equalToConstant: 44))
        constraints.append(checkoutButton.widthAnchor.constraint(equalToConstant: 100))

        constraints.append(toggleEnv.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(toggleEnv.bottomAnchor.constraint(equalTo: illustrationPurposes.topAnchor, constant: -20.0))
        
        constraints.append(illustrationPurposes.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor))
        constraints.append(illustrationPurposes.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor))
        constraints.append(illustrationPurposes.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor))
        
        NSLayoutConstraint.activate(constraints)
    }
}


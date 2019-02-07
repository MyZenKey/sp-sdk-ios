//
//  ViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

class ViewController: UIViewController {
    
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
    
    let illustrationPurposes: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "For illustration purposes only"
        label.textAlignment = .center
        return label
    }()

    /// Do any additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        layoutView()
    }
    
    @objc func checkoutPressed(sender: UIButton) {
        navigationController?.pushViewController(CheckoutViewController(), animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func layoutView() {
        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let safeAreaGuide = view.safeAreaLayoutGuide
        
        navigationItem.title = "ShoppingCart"
        
        view.addSubview(itemLabel)
        view.addSubview(checkoutButton)
        view.addSubview(illustrationPurposes)
        
        constraints.append(itemLabel.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor, constant: 10))
        constraints.append(itemLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 10))
        constraints.append(itemLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -10))
        
        constraints.append(checkoutButton.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor, constant: -100))
        constraints.append(checkoutButton.centerXAnchor.constraint(equalTo: safeAreaGuide.centerXAnchor))
        constraints.append(checkoutButton.heightAnchor.constraint(equalToConstant: 44))
        constraints.append(checkoutButton.widthAnchor.constraint(equalToConstant: 100))
        
        constraints.append(illustrationPurposes.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor))
        constraints.append(illustrationPurposes.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor))
        constraints.append(illustrationPurposes.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor))
        
        NSLayoutConstraint.activate(constraints)
    }
}


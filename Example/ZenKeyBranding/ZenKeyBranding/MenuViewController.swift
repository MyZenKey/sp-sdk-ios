//
//  MenuViewController.swift
//  ZenKeyBranding
//
//  Created by Adam Tierney on 4/11/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {

    let autolayoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("autolayout", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    let manualButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("frame layout", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let interfaceBuilderButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("interface builder", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            manualButton,
            autolayoutButton,
            interfaceBuilderButton,
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 30.0
        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        view.addSubview(stackView)
        
        [
            manualButton,
            autolayoutButton,
            interfaceBuilderButton,
        ].forEach() { $0.addTarget(self, action: #selector(handlePress(_:)), for: .touchUpInside) }

        [
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor),
        ].forEach( ) { $0.isActive = true }
    }
    
    @objc func handlePress(_ sender: UIButton) {
        switch sender {
        case autolayoutButton:
            navigationController?.pushViewController(
                AutolayoutViewController(),
                animated: true
            )

        case manualButton:
            navigationController?.pushViewController(
                ManualViewController(),
                animated: true
            )

        case interfaceBuilderButton:
            navigationController?.pushViewController(
                InterfaceBuilderViewController(),
                animated: true
            )
            
            break
        default:
            fatalError("unknown button")
        }
    }
}

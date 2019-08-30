//
//  AutolayoutViewController.swift
//  ZenKeyBranding
//
//  Created by Adam Tierney on 4/11/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit
import ZenKeySDK

class AutolayoutViewController: UIViewController {
    
    let buttonOne: ZenKeyBrandedButton = {
        let button = ZenKeyBrandedButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.updateBrandedText("Some Longer Sample Text")
        return button
    }()
    
    let buttonTwo: ZenKeyBrandedButton = {
        let button = ZenKeyBrandedButton()
        button.style = .light
        button.translatesAutoresizingMaskIntoConstraints = false
        button.updateBrandedText("Sample Text")
        return button
    }()
    
    let buttonThree: ZenKeyBrandedButton = {
        let button = ZenKeyBrandedButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .lightGray
        
        view.addSubview(buttonOne)
        view.addSubview(buttonTwo)
        view.addSubview(buttonThree)
        
        let buttonTwoWidthPreference = buttonTwo.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.754)
        buttonTwoWidthPreference.priority = .defaultHigh
        
        [
            buttonOne.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonOne.bottomAnchor.constraint(equalTo: buttonTwo.topAnchor, constant: -20),
            buttonTwo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonTwo.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            buttonThree.topAnchor.constraint(equalTo: buttonTwo.bottomAnchor, constant: 20),

            // checkout landscape mode to view the resizing behavior:
            // flexible width anchor:
            buttonTwoWidthPreference,
            // strict leading anchor:
            buttonThree.leadingAnchor.constraint(equalTo: buttonTwo.leadingAnchor)
        ].forEach() { $0.isActive = true }
        
    }
}
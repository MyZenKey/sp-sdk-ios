//
//  ManualViewController.swift
//  ProjectVerifyBranding
//
//  Created by Adam Tierney on 4/11/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit
import CarriersSharedAPI

class ManualViewController: UIViewController {
    let buttonOne: ProjectVerifyBrandedButton = {
        let button = ProjectVerifyBrandedButton()
        button.sizeToFit()
        return button
    }()
    
    let buttonTwo: ProjectVerifyBrandedButton = {
        let button = ProjectVerifyBrandedButton()
        button.style = .light
        button.sizeToFit()
        return button
    }()
    
    let buttonThree: ProjectVerifyBrandedButton = {
        let button = ProjectVerifyBrandedButton()
        button.autoresizingMask = [.flexibleWidth]
        button.sizeToFit()
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .lightGray
        
        view.addSubview(buttonOne)
        view.addSubview(buttonTwo)
        view.addSubview(buttonThree)
        
        updateButtonAnchors()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateButtonAnchors()
    }
    
    func updateButtonAnchors() {
        let center = view.center
        let yOffset = buttonOne.frame.height + 20.0
        buttonOne.center = CGPoint(x: center.x, y: center.y - yOffset)
        buttonTwo.center = center
        buttonThree.center = CGPoint(x: center.x, y: center.y + yOffset)
    }
}

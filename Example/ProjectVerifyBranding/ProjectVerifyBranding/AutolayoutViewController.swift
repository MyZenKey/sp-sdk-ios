//
//  AutolayoutViewController.swift
//  ProjectVerifyBranding
//
//  Created by Adam Tierney on 4/11/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit
import CarriersSharedAPI

class AutolayoutViewController: UIViewController {
    
    let buttonOne: ProjectVerifyBrandedButton = {
        let button = ProjectVerifyBrandedButton()
        return button
    }()
    
    let buttonTwo: ProjectVerifyBrandedButton = {
        let button = ProjectVerifyBrandedButton()
        return button
    }()
    
    let buttonThree: ProjectVerifyBrandedButton = {
        let button = ProjectVerifyBrandedButton()
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .lightGray
        
        view.addSubview(buttonOne)
        view.addSubview(buttonTwo)
        view.addSubview(buttonThree)
    }
}

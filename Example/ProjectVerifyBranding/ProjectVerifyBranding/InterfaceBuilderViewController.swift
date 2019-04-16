//
//  InterfaceBuilderViewController.swift
//  ProjectVerifyBranding
//
//  Created by Adam Tierney on 4/11/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit
import CarriersSharedAPI

class InterfaceBuilderViewController: UIViewController {
    
    @IBOutlet var buttonOne: ProjectVerifyBrandedButton!
    @IBOutlet var buttonTwo: ProjectVerifyBrandedButton!

    init() {
        super.init(nibName: "InterfaceBuilderViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buttonTwo.style = .light
    }
}

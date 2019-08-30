//
//  ManualViewController.swift
//  ZenKeyBranding
//
//  Created by Adam Tierney on 4/11/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit
import ZenKeySDK

class ManualViewController: UIViewController {
    let buttonOne: ZenKeyBrandedButton = {
        let button = ZenKeyBrandedButton()
        button.updateBrandedText("Sample Text")
        button.sizeToFit()
        return button
    }()

    // view landscape to see resizing behavior for buttons 2 + 3:
    
    lazy var buttonTwo: ZenKeyBrandedButton = {
        let button = ZenKeyBrandedButton()
        button.style = .light
        button.autoresizingMask = [.flexibleWidth]
        button.updateBrandedText("Some Longer Sample Text")
        button.sizeToFit()
        return button
    }()
    
    let buttonThree: ZenKeyBrandedButton = {
        let button = ZenKeyBrandedButton()
        button.autoresizingMask = [.flexibleRightMargin]
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

        // center positioning
        buttonOne.center = CGPoint(
            x: center.x,
            y: center.y - buttonOne.frame.height - 20.0
        )
            
        buttonTwo.center = center
        
        // frame positioning
        var frame = buttonThree.frame
        frame.origin = CGPoint(
            x: buttonTwo.frame.minX,
            y: buttonTwo.frame.minY + buttonTwo.frame.height + 20
        )
        buttonThree.frame = frame
    }
}
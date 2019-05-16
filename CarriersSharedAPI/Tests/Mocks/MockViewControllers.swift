//
//  MockViewControllers.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 5/16/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

// swiflint:disable unused_setter_value

class MockWindowView: UIView {
    override var window: UIWindow? {
        return UIWindow()
    }
}

class MockWindowViewController: UIViewController {
    override var view: UIView! {
        get { return MockWindowView() }
        set {}
    }
}

// swiflint:enable unused_setter_value

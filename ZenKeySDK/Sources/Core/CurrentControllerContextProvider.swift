//
//  CurrentControllerContextProvider.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 4/12/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

protocol CurrentControllerContextProvider {
    var currentController: UIViewController? { get }
}

class DefaultCurrentControllerContextProvider: CurrentControllerContextProvider {
    var currentController: UIViewController? {
        return UIViewController.currentController
    }
}

extension UIViewController {
    static var currentController: UIViewController? {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            return nil
        }
        var currentViewController: UIViewController? = rootViewController
        while let nextController = currentViewController?.presentedViewController {
            currentViewController = nextController
        }
        return currentViewController
    }
}

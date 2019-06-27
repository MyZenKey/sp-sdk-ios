//
//  UIViewController+Helpers.swift
//  BankApp
//
//  Created by Adam Tierney on 6/26/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import UIKit
import CarriersSharedAPI

extension UIViewController {

    func completeFlow(withError error: AuthorizationError) {
        switch error.errorType {
        case .requestDenied:
            showAlert(
                title: "The User Cancelled the Request",
                message: "Comeback later if you change your mind."
            )
        default:
            showAlert(title: "Error", message: "An error occured")
        }
    }

    func cancelFlow() {
        showAlert(title: "Cancelled", message: "The transaction was cancelled")
    }

    func showAlert(title: String, message: String) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        controller.addAction(
            UIAlertAction(title: "Okay",
                          style: .default,
                          handler: { [weak self] _ in
                            self?.dismiss(animated: true, completion: nil)
            })
        )
        present(controller, animated: true, completion: nil)
    }

    func launchHomeScreen() {
        // TODO: - fix this up, shouldn't be digging into app delegate but quickest refactor
        let appDelegate = UIApplication.shared.delegate! as! AppDelegate
        appDelegate.launchHomeScreen()
    }

    func launchLoginScreen() {
        // TODO: - fix this up, shouldn't be digging into app delegate but quickest refactor
        let appDelegate = UIApplication.shared.delegate! as! AppDelegate
        appDelegate.launchLoginScreen()
    }
}

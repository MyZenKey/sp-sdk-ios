//
//  UIViewController+ExampleApps.swift
//  Example Apps
//
//  Created by Adam Tierney on 7/12/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import UIKit
import CarriersSharedAPI

// MARK: - View Helpers

extension UIViewController {
    func getSafeLayoutGuide() -> UILayoutGuide {
        if #available(iOS 11.0, *) {
            return view.safeAreaLayoutGuide
        } else {
            // Fallback on earlier versions
            return view.layoutMarginsGuide
        }
    }
}

// MARK: - Flow Mangement

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

    func showAlert(title: String, message: String, onDismiss: (() -> Void)? = nil) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        controller.addAction(
            UIAlertAction(title: "Okay",
                          style: .default,
                          handler: { _ in
                            onDismiss?()
            })
        )
        present(controller, animated: true, completion: nil)
    }
}

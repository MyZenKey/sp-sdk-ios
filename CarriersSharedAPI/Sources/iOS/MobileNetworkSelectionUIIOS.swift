//
//  MobileNetworkSelectionUIIOS.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 4/26/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
import SafariServices

class MobileNetworkSelectionUIIOS: NSObject, MobileNetworkSelectionUIProtocol, SFSafariViewControllerDelegate {

    private var safariController: SFSafariViewController?
    private var onUIDidCancel: (() -> Void)?

    func showMobileNetworkSelectionUI(
        fromController viewController: UIViewController,
        usingURL url: URL,
        onUIDidCancel: @escaping () -> Void) {

        self.onUIDidCancel = onUIDidCancel

        let safariController = SFSafariViewController(
            url: url
        )

        safariController.delegate = self

        // earlier versions just default to "Done" which is fine.
        if #available(iOS 11.0, *) {
            safariController.dismissButtonStyle = .cancel
        }

        self.safariController = safariController

        viewController.present(safariController, animated: true, completion: nil)
    }

    func close(completion: @escaping () -> Void) {

        guard let presentingViewController = safariController?.presentingViewController else {
            completion()
            return
        }

        presentingViewController.dismiss(
            animated: true,
            completion: {
                completion()
        })
    }

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        onUIDidCancel?()
    }
}

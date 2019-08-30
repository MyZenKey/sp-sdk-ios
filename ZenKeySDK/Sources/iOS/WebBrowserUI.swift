//
//  WebBrowserUI.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 4/26/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
import SafariServices

class WebBrowserUI: NSObject, SFSafariViewControllerDelegate {

    private var safariController: SFSafariViewController?
    private var onUIDidCancel: (() -> Void)?

    func showBrowserUI(
        fromController viewController: UIViewController,
        forWebInterface url: URL,
        onUIDidCancel: @escaping () -> Void) {

        self.onUIDidCancel = onUIDidCancel

        if viewController.transitionCoordinator != nil {
            // in the case that there is a transition in progress, we need to follow the transition
            // and create the safari vc in the completion (or it will appear blank).
            viewController.transitionCoordinator?.animate(alongsideTransition: nil) { _ in
                let safariController = self.newSafariViewController(url: url)
                self.safariController = safariController
                viewController.present(safariController, animated: true, completion: nil)
            }
        } else {
            let safariController = self.newSafariViewController(url: url)
            self.safariController = safariController
            viewController.present(safariController, animated: true, completion: nil)
        }
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

private extension WebBrowserUI {
    func newSafariViewController(url: URL) -> SFSafariViewController {
        let safariController = SFSafariViewController(
            url: url
        )

        safariController.delegate = self

        // earlier versions just default to "Done" which is fine.
        if #available(iOS 11.0, *) {
            safariController.dismissButtonStyle = .cancel
        }

        return safariController
    }
}

extension WebBrowserUI: MobileNetworkSelectionUIProtocol {
    func showMobileNetworkSelectionUI(
        fromController viewController: UIViewController,
        usingURL url: URL,
        onUIDidCancel: @escaping () -> Void) {
        showBrowserUI(
            fromController: viewController,
            forWebInterface: url,
            onUIDidCancel: onUIDidCancel
        )
    }
}

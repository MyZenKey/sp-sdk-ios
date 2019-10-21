//
//  WebBrowserUI.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 4/26/19.
//  Copyright © 2019 XCI JV, LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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

        // handle iOS 13 defaulting to .pageSheet style instead of .fullScreen
        safariController.modalPresentationStyle = .fullScreen

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

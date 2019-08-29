//
//  OpenIdURLResolver.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 3/6/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

/// A url resolver which uses universal links
class OpenIdURLResolverIOS: OpenIdURLResolverProtocol {
    private var webBrowserUI: WebBrowserUI = WebBrowserUI()

    func resolve(
        request: OpenIdAuthorizationRequest,
        fromViewController viewController: UIViewController,
        onCancel: @escaping OpenIdURLResolverDidCancel) {

        let authoriztionRequestURL = request.authorizationRequestURL
        UIApplication.shared.open(
            authoriztionRequestURL,
            options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: true]
        ) { success in
            guard success else {
                // if the request can't be performed locally, fall back to safari:
                self.performSafariAuthorization(
                    url: authoriztionRequestURL,
                    fromViewController: viewController,
                    onCancel: onCancel
                )
                return
            }
        }
    }

    func close(completion: @escaping () -> Void) {
        webBrowserUI.close(completion: completion)
    }

    func performSafariAuthorization(
        url: URL,
        fromViewController viewController: UIViewController,
        onCancel: @escaping OpenIdURLResolverDidCancel) {
        webBrowserUI.showBrowserUI(fromController: viewController,
                                   forWebInterface: url,
                                   onUIDidCancel: onCancel)
    }
}

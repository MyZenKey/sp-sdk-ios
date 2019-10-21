//
//  OpenIdURLResolver.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 3/6/19.
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

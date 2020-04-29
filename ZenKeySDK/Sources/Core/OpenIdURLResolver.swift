//
//  OpenIdURLResolverProtocol.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 5/7/19.
//  Copyright © 2019-2020 ZenKey, LLC.
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

typealias OpenIdURLResolverDidCancel = () -> Void

/// An abstraction over OpenId Universal Link vs in app resolution (ie. via a browser or native ui).
protocol OpenIdURLResolverProtocol {

    /// Show ui for the provied request parameter. The interface expects that the contract will
    /// be fulfilled via the request's redirect uri. For this reason, the only terminal event we
    /// expect to be originated from this flow is a user interaction trigged cancel event.
    ///
    /// - Parameters:
    ///   - request: the Open Id Authorization request.
    ///   - viewController: the view contorller responsible for presenting this request.
    ///   - onCancel: the block to invoke in the event of user triggered cancellation.
    func resolve(
        request: OpenIdAuthorizationRequest,
        fromViewController viewController: UIViewController,
        onCancel: @escaping OpenIdURLResolverDidCancel)

    /// Close the ui if currently prsented and can be closed.
    ///
    /// - Parameter completion: closure to execute when the ui has been dismissed.
    func close(completion: @escaping () -> Void)
}

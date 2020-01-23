//
//  BrandingProvider.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 5/7/19.
//  Copyright © 2019 ZenKey, LLC.
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

public struct Branding: Equatable {
    /// The branded icon
    public let icon: UIImage?

    /// The branded carrier text
    public let carrierText: String?

    /// The branded carrier icon
    public let carrierIcon: String?

    static let `default` = Branding(
        icon: ImageUtils.image(named: "zk-icon-connect"),
        carrierText: nil,
        carrierIcon: nil
    )
}

// NOTE: since config retrieval will need to also support asyc cases for there to be a reasonable
// chance of recievieng an up to date config for a button that will most likly appear on one of the
// initial views of the application.
extension OpenIdConfig {
    var buttonBranding: Branding {
        // there are 2 other fields spec'd in the external api v21 document for image urls. it is
        // not yet clear how they'll be used.
        // for this proof of concept, we'll only use the carrier text and forward it:
        guard let carrierText = linkBranding else {
            return .default
        }

        return Branding(
            icon: ImageUtils.image(named: "zk-icon-connect"),
            carrierText: carrierText,
            carrierIcon: nil
        )
    }
}

//
//  BrandingProvider.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 5/7/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

public struct Branding: Equatable {
    /// The branded icon
    public let icon: UIImage?

    /// The branded carrier text
    public let carrierText: String?

    /// The branded carrier icon
    public let carrierIcon: String?

    static let `default` = Branding(
        icon: ImageUtils.image(named: "pv-icon-connect"),
        carrierText: nil,
        carrierIcon: nil
    )
}

protocol BrandingProvider: AnyObject {
    var buttonBranding: Branding { get }

    var brandingDidChange: ((Branding) -> Void)? { get set }
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
            icon: ImageUtils.image(named: "pv-icon-connect"),
            carrierText: carrierText,
            carrierIcon: nil
        )
    }
}

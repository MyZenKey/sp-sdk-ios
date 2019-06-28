//
//  BrandingProvider.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 5/7/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

enum Branding {
    case `default`
}

protocol BrandingProvider {
    var branding: Branding { get }
    // FUTURE: probably add a on branding update here
}

// TODO: once we have an idea of how OpenIdConfig will expose branding we can import from the
// discovery api and support forming a branding type in this extension.
// NOTE: since config retrieval will need to also support asyc cases for there to be a reasonable
// chance of recievieng an up to date config for a button that will most likly appear on one of the
// initial views of the application.
extension OpenIdConfig {
    var branding: Branding {
        return .default
    }
}

extension Branding {
    /// The button's icon. Icons should be provided as a template image.
    var icon: UIImage? {
        return ImageUtils.image(named: "pv-icon-connect")
    }
}

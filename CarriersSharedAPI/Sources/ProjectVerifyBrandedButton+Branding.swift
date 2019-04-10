//
//  ProjectVerifyBrandedButton+Branding.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 4/10/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

extension ProjectVerifyBrandedButton {
    func brandingFromCache() -> Branding {
        guard
            let primarySIM = carrierInfoService.primarySIM,
            let config = configCacheService.config(
                forSIMInfo: primarySIM,
                allowStaleRecords: true) else {
                    return .default
        }
        
        return config.branding
    }
}

// TODO: once we have an idea of how OpenIdConfig will expose branding we can import from the
// discovery api and support forming a branding type in this extension.
// NOTE: since config retrieval will need to also support asyc cases for there to be a reasonable
// chance of recievieng an up to date config for a button that will most likly appear on one of the
// initial views of the application.
extension OpenIdConfig {
    var branding: ProjectVerifyBrandedButton.Branding {
        return .default
    }
}

extension ProjectVerifyBrandedButton.Branding {
    var primaryText: String {
        return Localization.Buttons.signInWithProjectVerify
    }
    
    func icon(forUI hint: ProjectVerifyBrandedButton.UIHint) -> UIImage? {
        return ImageUtils.image(named: "pv-icon-connect-light")
    }
}

extension ProjectVerifyBrandedButton {
    struct ColorScheme {
        let foreground: UIColor
        let background: UIColor
        let highlight: UIColor
    }
    
    var colorScheme: ColorScheme {
        switch uiHint {
        case .dark:
            return ColorScheme(
                foreground: .projectVerifyWhite,
                background: .projectVerifyGreen,
                highlight: .projectVerifyDimGreen
            )

        case .light:
            return ColorScheme(
                foreground: .projectVerifyGray,
                background: .projectVerifyWhite,
                highlight: .projectVerifyDimGray
            )
        }
    }
}

private extension UIColor {
    static let projectVerifyWhite = UIColor.white
    static let projectVerifyGreen = UIColor(red: 46/255, green: 173/255, blue: 69/255, alpha: 1)
    static let projectVerifyDimGreen = UIColor(red: 46/255, green: 173/255, blue: 69/255, alpha: 0.3)
    static let projectVerifyGray = UIColor(red: 68/255, green: 68/255, blue: 68/255, alpha: 1)
    static let projectVerifyDimGray = UIColor(red: 68/255, green: 68/255, blue: 68/255, alpha: 0.3)
}

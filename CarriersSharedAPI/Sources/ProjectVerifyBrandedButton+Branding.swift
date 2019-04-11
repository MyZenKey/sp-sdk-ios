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

extension ProjectVerifyBrandedButton.Branding {
    /// the buttons title label text.
    var primaryText: String {
        return Localization.Buttons.signInWithProjectVerify
    }
    
    /// The button's icon. Icons should be provided as a template image.
    var icon: UIImage? {
        return ImageUtils.image(named: "pv-icon-connect")
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

extension ProjectVerifyBrandedButton.Appearance {
    static let darkAppearance = ProjectVerifyBrandedButton.Appearance(
        title: ColorScheme(normal: .buttonWhite, highlighted: .buttonDimGray),
        image: ColorScheme(normal: .buttonWhite, highlighted: .buttonDimGray),
        background: ColorScheme(normal: .buttonGreen, highlighted: .buttonDimGreen)
    )

    static let lightAppearance = ProjectVerifyBrandedButton.Appearance(
        title: ColorScheme(normal: .buttonGray, highlighted: .buttonDimGray),
        image: ColorScheme(normal: .buttonGreen, highlighted: .buttonDimGray),
        background: ColorScheme(normal: .buttonWhite, highlighted: .buttonDimLightGray)
    )
}

extension ProjectVerifyBrandedButton {
    var appearance: Appearance {
        switch style {
        case .dark:
            return .darkAppearance
        case .light:
            return .lightAppearance
        }
    }
}

private extension UIColor {
    static let buttonWhite = UIColor.white
    static let buttonGreen = UIColor(red: 46/255, green: 173/255, blue: 69/255, alpha: 1)
    static let buttonDimGreen = UIColor(red: 46/255, green: 173/255, blue: 69/255, alpha: 0.5)
    static let buttonGray = UIColor(red: 68/255, green: 68/255, blue: 68/255, alpha: 1)
    static let buttonDimGray = UIColor(red: 68/255, green: 68/255, blue: 68/255, alpha: 0.5)
    static let buttonDimLightGray = UIColor(red: 68/255, green: 68/255, blue: 68/255, alpha: 0.2)
}

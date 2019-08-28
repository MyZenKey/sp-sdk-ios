//
//  LocalizationUtils.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 4/5/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

enum Localization {
    enum Buttons {
        static let signInWithProjectVerify = LocalizationUtils.localizedString("Sign in with ZenKey")
        static let continueWithProjectVerify = LocalizationUtils.localizedString("Continue with ZenKey")
    }
}

private class LocalizationUtils {
    static func localizedString(_ key: String) -> String {
        return NSLocalizedString(
            key,
            tableName: nil,
            bundle: Bundle(for: LocalizationUtils.self),
            value: "",
            comment: ""
        )
    }
}

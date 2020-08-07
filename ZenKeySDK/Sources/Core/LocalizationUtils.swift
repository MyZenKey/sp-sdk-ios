//
//  LocalizationUtils.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 4/5/19.
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

import Foundation

enum Localization {
    enum Buttons {
        static let signInWithZenKey = LocalizationUtils.localizedString("Sign in with ZenKey")
        static let continueWithZenKey = LocalizationUtils.localizedString("Continue with ZenKey")
    }
    enum Alerts {
        static let ok = LocalizationUtils.localizedString("OK")
        static let error = LocalizationUtils.localizedString("Error")
    }
    enum Errors {
        static let incomingRequest = LocalizationUtils.localizedString("Your last request could not be completed")
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

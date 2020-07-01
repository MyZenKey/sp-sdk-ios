//
//  Localized.swift
//  ZenKey-SDK-Example
//
//  Created by Chad Mealey on 4/16/20.
//  Copyright © 2020 ZenKey, LLC.
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

/// Provides localized strings for user-facing content.
/// Not used for logged strings as they should remain in the developers’ language.
internal enum Localized {
    internal enum Error {
        internal static let unrecognized = Localized.text("Error.Unrecognized")
        internal static let invalidRequest = Localized.text("Error.InvalidRequest")
        internal static let requestDenied = Localized.text("Error.RequestDenied")
        internal static let requestTimeout = Localized.text("Error.RequestTimeout")
        internal static let server = Localized.text("Error.ServerError")
        internal static let networkFailure = Localized.text("Error.NetworkFailure")
        internal static let configuration = Localized.text("Error.ConfigurationError")
        internal static let discoveryState = Localized.text("Error.DiscoveryStateError")
        internal static let unknown = Localized.text("Error.UnknownError")

    }
    internal enum Home {
        internal static let activities = Localized.text("Home.Activities")
        internal static let signOut = Localized.text("Home.SignOut")
        internal static let alertTitle = Localized.text("Home.AlertTitle")
        internal static let alertText = Localized.text("Home.AlertText")
        internal static let welcome = {
            String(format: Localized.text("Home.Welcome"), $0)
        }
    }
    internal enum SignIn {
        internal static let divider = Localized.text("SignIn.Divider")
        internal static let userPlaceholder = Localized.text("SignIn.UserPlaceholder")
        internal static let passwordPlaceholder = Localized.text("SignIn.PasswordPlaceholder")
        internal static let buttonTitle = Localized.text("SignIn.ButtonTitle")
        internal static let authorizing = Localized.text("SignIn.Authorizing")
        internal static let alertTitle = Localized.text("SignIn.AlertTitle")
        internal static let alertText = Localized.text("SignIn.AlertText")
    }
    internal enum App {
        internal static let demoText = Localized.text("App.DemoText")
    }
    internal enum Alert {
        internal static let errorTitle = Localized.text("Alert.ErrorTitle")
        internal static let ok = Localized.text("Alert.OK")
    }
}

extension Localized {
    static func text(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
}

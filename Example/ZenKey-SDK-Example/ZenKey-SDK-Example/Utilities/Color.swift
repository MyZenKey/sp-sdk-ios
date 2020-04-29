//
//  Color.swift
//  ZenKey-SDK-Example
//
//  Created by Chad Mealey on 4/17/20.
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
import UIKit

/// Access to semantic colors. Opportunity to provide backup colors on older systems
/// or semantic system colors when building for iOS 13 or higher.
internal enum Color {
    internal enum Background {
        internal static let app = Color.getColor("appBackground")
        internal static let home = Color.getColor("homeBackground")
        internal static let card = Color.getColor("cardBackground")
        internal static let button = Color.getColor("buttonBackground")
        internal static let buttonDisabled = Color.getColor("buttonBackgroundDisabled")
    }
    internal enum Text {
        internal static let main = Color.getColor("mainText")
        internal static let secondary = Color.getColor("secondaryText")
        internal static let buttonDisabled = Color.getColor("buttonTextDisabled")
    }
    internal static let shadow = Color.getColor("shadow")
    internal static let divider = Color.getColor("divider")
    internal static let inputBorder = Color.getColor("inputBorder")
}

private extension Color {
    static func getColor(_ name: String) -> UIColor {
        guard let color = UIColor(named: name) else {
            fatalError("color \(name) missing from asset catalogue")
        }
        return color
    }
}

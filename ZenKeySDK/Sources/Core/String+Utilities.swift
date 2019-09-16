//
//  String+Utilities.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 7/8/19.
//  Copyright © 2019 XCI JV, LLC.
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

extension String {
    func toSIMInfo() -> Result<SIMInfo, MobileNetworkSelectionError> {
        guard count == 6 else {
            return .error(.invalidMCCMNC)
        }
        var copy = self
        let mnc = copy.popLast(3)
        let mcc = copy.popLast(3)
        return .value(SIMInfo(mcc: String(mcc), mnc: String(mnc)))
    }
}

private extension String {
    /// removes and returns the last n characters from the string
    mutating func popLast(_ number: Int) -> Substring {
        let bounded = min(number, count)
        let substring = suffix(bounded)
        removeLast(bounded)
        return substring
    }
}

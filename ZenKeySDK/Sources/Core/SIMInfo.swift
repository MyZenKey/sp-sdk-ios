//
//  SIMInfo.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/21/19.
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

struct SIMInfo: Equatable {
    let mcc: String
    let mnc: String

    init(mcc: String, mnc: String) {
        self.mcc = mcc
        self.mnc = mnc
    }
}

extension SIMInfo {
    /// a string with the format '{mcc}{mnc}'
    var networkString: String {
        return "\(mcc)\(mnc)"
    }
}

//
//  SIMInfo.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/21/19.
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

public protocol SIMProtocol {
    var mccmnc: String { get }
    var mcc: String { get }
    var mnc: String { get }
}

public extension SIMProtocol {
    var mcc: String {
        String(mccmnc.prefix(3))
    }
    var mnc: String {
        String(mccmnc.suffix(3))
    }

}

struct SIMInfo: Equatable, SIMProtocol {
    let mccmnc: String

    init(mcc: String, mnc: String) {
        self.mccmnc = "\(mcc)\(mnc)"
    }
}

//
//  SIMInfo.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/21/19.
//  Copyright © 2018 XCI JV, LLC. ALL RIGHTS RESERVED.
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

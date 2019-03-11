//
//  SIMInfo.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/21/19.
//  Copyright © 2018 XCI JV, LLC. ALL RIGHTS RESERVED.
//

import Foundation
import CoreTelephony

struct SIMInfo: Equatable {
    let mcc: String
    let mnc: String

    init(mcc: String, mnc: String) {
        self.mcc = mcc
        self.mnc = mnc
    }
}

extension SIMInfo {
    func carrier(usingCarrierLookUp cache: NetworkIdentifierCache) -> Carrier {
        return cache.carrier(forMcc: mcc, mnc: mnc)
    }
}

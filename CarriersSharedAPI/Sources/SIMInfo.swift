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
    struct IDPair: Equatable {
        let mcc: String
        let mnc: String
    }

    let identifiers: IDPair
    let carrier: Carrier

    init(identifiers: IDPair) {
        self.identifiers = identifiers
        self.carrier = SIMInfo.carrier(fromIDPair: identifiers)
    }

    init(mcc: String, mnc: String) {
        self.init(identifiers: IDPair(mcc: mcc, mnc: mnc))
    }
}

private extension SIMInfo {
    static func carrier(fromIDPair identifiers: SIMInfo.IDPair) -> Carrier {
        let carrier = Carrier.carriers.first() { carrier in
            carrier.networkIdentifiers.has(mcc: identifiers.mcc, mnc: identifiers.mnc)
        }
        return carrier ?? .unknown
    }
}

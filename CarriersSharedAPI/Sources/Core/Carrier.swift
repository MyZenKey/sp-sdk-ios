//
//  Carrier.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/21/19.
//  Copyright © 2018 XCI JV, LLC. All rights reserved.
//

import Foundation

public enum Carrier: String, Equatable {
    case att, tmobile, verizon, sprint

    var shortName: String {
        switch self {
        case .att: return "att"
        case .tmobile: return "tmo"
        case .verizon: return "vzn"
        case .sprint: return "spt"
        }
    }
}

struct NetworkIdentifierCache {
    struct NetworkIdentifiers {
        private let mccToMNCMap: [String: [String]]
        init(_ mccToMNCMap: [String: [String]]) {
            self.mccToMNCMap = mccToMNCMap
        }

        func has(mcc: String, mnc: String) -> Bool {
            guard
                let mncs = mccToMNCMap[mcc],
                mncs.contains(mnc) else {
                    return false
            }
            return true
        }
    }

    private var identifiersByCarrier: [Carrier: NetworkIdentifiers]
    private init(identifiersByCarrier: [Carrier: NetworkIdentifiers]) {
        self.identifiersByCarrier = identifiersByCarrier
    }

    func carrier(forMcc mcc: String, mnc: String) -> Carrier? {
        var matchedCarrier: Carrier? = nil
        // use for loop to exit early:
        // swiftlint:disable:next unused_enumerated
        for (_, element) in identifiersByCarrier.enumerated() {
            let identifiers = element.value
            if identifiers.has(mcc: mcc, mnc: mnc) {
                let carrier = element.key
                matchedCarrier = carrier
                break
            }
        }
        return matchedCarrier
    }

    private static let attCodes = NetworkIdentifiers([
        "310": [
            "007", "560", "680", "150", "170", "380", "410",
        ],
    ])

    private static let tmobileCodes = NetworkIdentifiers([
        "310": [
            "160", "200", "210", "220", "230", "240", "250", "260", "270", "310", "490", "660", "800",
        ],
    ])

    private static let verizonCodes = NetworkIdentifiers([
        "310": [ "010", "012", "013", "590", "890", "910"],
        "311": [
            "110", "270", "271", "272", "273", "274", "275", "276", "277", "278", "279", "280",
            "281", "282", "283", "284", "285", "286", "287", "288", "289", "390", "480", "481",
            "482", "483", "484", "485", "486", "487", "488", "489",
        ],
    ])

    private static let sprintCodes = NetworkIdentifiers([
        "310": ["120"],
        "312": ["530"],
    ])

    static let bundledCarrierLookup = NetworkIdentifierCache(
        identifiersByCarrier: [
            Carrier.tmobile: tmobileCodes,
            Carrier.att: attCodes,
            Carrier.verizon: verizonCodes,
            Carrier.sprint: sprintCodes,
        ]
    )
}

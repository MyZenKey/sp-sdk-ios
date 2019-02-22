//
//  Carrier.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/21/19.
//  Copyright © 2018 XCI JV, LLC. All rights reserved.
//

import Foundation

enum Carrier {
    enum ShortName: String {
        case att = "att"
        case tmobile = "tmo"
        case verizon = "vzn"
        case sprint = "spt"
        case unknown
    }

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

    case att, tmobile, verizon, sprint, unknown

    var shortName: ShortName {
        switch self {
        case .att:
            return ShortName.att
        case .tmobile:
            return ShortName.tmobile
        case .verizon:
            return ShortName.verizon
        case .sprint:
            return ShortName.sprint
        case .unknown:
            return ShortName.unknown
        }
    }

    var networkIdentifiers: NetworkIdentifiers {
        switch self {
        case .att: return Carrier.attCodes
        case .tmobile: return Carrier.tmobileCodes
        case .verizon: return Carrier.verizonCodes
        case .sprint: return Carrier.sprintCodes
        case .unknown: return NetworkIdentifiers([:])
        }
    }

    static let carriers: [Carrier] = [.att, .tmobile, .verizon, .unknown]

    private static let attCodes = NetworkIdentifiers([
        "310": [
            "070", "560", "410", "380", "170", "150", "680", "980"
        ],
    ])

    private static let tmobileCodes = NetworkIdentifiers([
        "310": [
            "160", "200", "210", "220", "230", "240", "250", "260", "270", "310", "490", "660", "800"
        ],
    ])

    private static let verizonCodes = NetworkIdentifiers([
        "310": [ "010", "012", "013", "590", "890", "910"],
        "311": [
            "110", "270", "271", "272", "273", "274", "275", "276", "277", "278", "279", "280",
            "281", "282", "283", "284", "285", "286", "287", "288", "289", "390", "480", "481",
            "482", "483", "484", "485", "486", "487", "488", "489"
        ],
    ])

    private static let sprintCodes = NetworkIdentifiers([
        "310": ["120"],
        "312": ["530"],
    ])
}

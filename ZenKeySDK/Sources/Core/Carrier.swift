//
//  Carrier.swift
//  ZenKeySDK
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

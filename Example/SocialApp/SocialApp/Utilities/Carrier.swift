//
//  Carrier.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import Foundation
import CoreTelephony

class Carrier {
    enum Identifier {
        case att
        case sprint
        case tMobile
        case verizon
    }
    
    let networkInfo = CTTelephonyNetworkInfo()

    var mobileCountryCode: String? {
        return networkInfo.subscriberCellularProvider?.mobileCountryCode
    }

    var mobileNetworkCode: String? {
        return networkInfo.subscriberCellularProvider?.mobileNetworkCode
    }

    var name: String {
        // TODO: Remove the default to "AT&T" for production use. Leaving AT&T for now allows basic simulator testing.
        return networkInfo.subscriberCellularProvider?.carrierName ?? "AT&T (Simulator)"
    }

    /// Return "at&t", "verizon", "t-mobile", or nil.
    var identifier: Identifier? {
        if let mobileCountryCode = self.mobileCountryCode,
            let mobileNetworkCode = self.mobileNetworkCode {
            switch mobileCountryCode {
                // United States
            case "310":
                switch mobileNetworkCode {
                // AT&T
                case "070", "560", "680":
                    return .att
                // Verizon
                case "010", "012", "013", "590", "890", "910":
                    return .verizon
                // T-Mobile
                case "160", "200", "210", "220", "230", "240", "250", "260",
                     "270", "310", "490", "660", "800":
                    return .tMobile

                default:
                    return nil
                }

            case "311":
                switch mobileNetworkCode {
                // Verizon
                case "110", "270", "271", "272", "273", "274", "275", "276",
                     "277", "278", "279", "280", "281", "282", "283", "284",
                     "285", "286", "287", "288", "289", "390", "480", "481",
                     "482", "483", "484", "485", "486", "487", "488", "489":
                    return .verizon

                default:
                    return nil
                }

            default:
                return nil
            }
        } else {
            return nil
        }
    }
}

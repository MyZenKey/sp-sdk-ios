//
//  String+Utilities.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 7/8/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
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

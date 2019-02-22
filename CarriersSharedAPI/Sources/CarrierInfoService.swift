//
//  CarrierInfo.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/21/19.
//  Copyright © 2018 XCI JV, LLC. All rights reserved.
//

import Foundation

/// This service provides up to date information about the current device's Carrier information
protocol CarrierInfoServiceProtocol {
    var primarySIM: SIMInfo? { get }
}

extension CarrierInfoServiceProtocol {
    var hasSIM: Bool {
        return primarySIM != nil
    }
}

class CarrierInfoService: CarrierInfoServiceProtocol {
    var primarySIM: SIMInfo? {
        guard sims.count > 0 else {
            return nil
        }
        return sims[0]
    }

    private let mobileNetworkInfoProvder: MobileNetworkInfoProvider
    private var sims: [SIMInfo]

    init(mobileNetworkInfoProvder: MobileNetworkInfoProvider) {
        self.mobileNetworkInfoProvder = mobileNetworkInfoProvder
        self.sims = CarrierInfoService.current(fromNetworkInfo: mobileNetworkInfoProvder)
        mobileNetworkInfoProvder.subscribeToNetworkInfoChanges() { [weak self] in
            self?.updateCarrierInfo()
        }
    }

    private func updateCarrierInfo() {
        self.sims = CarrierInfoService.current(fromNetworkInfo: mobileNetworkInfoProvder)
    }

    static func current(fromNetworkInfo mobileNetworkInfo: MobileNetworkInfoProvider) -> [SIMInfo] {
        return mobileNetworkInfo.carriersForCurrentSIMs.compactMap() { carrier in
            guard
                let mcc = carrier.mobileCountryCode,
                let mnc = carrier.mobileNetworkCode else {
                    return nil
            }
            return SIMInfo(mcc: mcc, mnc: mnc)
        }
    }
}

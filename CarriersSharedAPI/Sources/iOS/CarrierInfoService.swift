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

        return SIMInfo(mcc: "310", mnc: "380")

        guard sims.count > 0 else {
            return nil
        }
        return sims[0]
    }

    private let mobileNetworkInfoProvider: MobileNetworkInfoProvider
    private var sims: [SIMInfo]

    init(mobileNetworkInfoProvider: MobileNetworkInfoProvider) {
        self.mobileNetworkInfoProvider = mobileNetworkInfoProvider
        self.sims = mobileNetworkInfoProvider.currentSIMs
        mobileNetworkInfoProvider.subscribeToNetworkInfoChanges() { [weak self] newSIMs in
            self?.sims = newSIMs
        }
    }

    func refreshSIMs() {
        self.sims = mobileNetworkInfoProvider.currentSIMs
    }
}

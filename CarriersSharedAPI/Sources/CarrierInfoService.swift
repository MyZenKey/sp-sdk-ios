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
        self.sims = mobileNetworkInfoProvder.currentSIMs
        mobileNetworkInfoProvder.subscribeToNetworkInfoChanges() { [weak self] newSIMs in
            self?.sims = newSIMs
        }
    }

    func refreshSIMs() {
        self.sims = mobileNetworkInfoProvder.currentSIMs
    }
}

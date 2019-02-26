//
//  MockMobileNetworkInfoProvider.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/25/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
import CoreTelephony
@testable import CarriersSharedAPI

class MockMobileNetworkInfoProvider: MobileNetworkInfoProvider {
    var onNetworkInfoDidUpdate: NetworkInfoUpdateHanlder?
    var currentSIMs: [SIMInfo] = []

    func subscribeToNetworkInfoChanges(onNetworkInfoDidUpdate: NetworkInfoUpdateHanlder?) {
        self.onNetworkInfoDidUpdate = onNetworkInfoDidUpdate
    }

    func clear() {
        currentSIMs = []
        onNetworkInfoDidUpdate = nil
    }
}

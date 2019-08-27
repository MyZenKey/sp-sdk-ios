//
//  MockMobileNetworkInfoProvider.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/25/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
import CoreTelephony
@testable import ZenKeySDK

class MockMobileNetworkInfoProvider: MobileNetworkInfoProvider {
    var onNetworkInfoDidUpdate: NetworkInfoUpdateHandler?
    var currentSIMs: [SIMInfo] = []

    func subscribeToNetworkInfoChanges(onNetworkInfoDidUpdate: NetworkInfoUpdateHandler?) {
        self.onNetworkInfoDidUpdate = onNetworkInfoDidUpdate
    }

    func clear() {
        currentSIMs = []
        onNetworkInfoDidUpdate = nil
    }
}

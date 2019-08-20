//
//  MobileNetworkInfoProvider.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/21/19.
//  Copyright © 2018 XCI JV, LLC. All rights reserved.
//

import Foundation
import CoreTelephony

protocol MobileNetworkInfoProvider: AnyObject {

    typealias NetworkInfoUpdateHandler = ([SIMInfo]) -> Void

    var currentSIMs: [SIMInfo] { get }

    func subscribeToNetworkInfoChanges(onNetworkInfoDidUpdate: NetworkInfoUpdateHandler?)
}

extension CTTelephonyNetworkInfo: MobileNetworkInfoProvider {
    var currentSIMs: [SIMInfo] {
        var simCarriers: [CTCarrier] = []
        if #available(iOS 12.0, *) {
            if let cellProviders = serviceSubscriberCellularProviders {
                simCarriers = Array(cellProviders.values)
            }
        } else {
            if let providerInfo = subscriberCellularProvider {
                simCarriers = [providerInfo]
            }
        }

        return simCarriers.compactMap() { carrier in
            guard
                let mcc = carrier.mobileCountryCode,
                let mnc = carrier.mobileNetworkCode else {
                    return nil
            }
            return SIMInfo(mcc: mcc, mnc: mnc)
        }
    }

    func subscribeToNetworkInfoChanges(onNetworkInfoDidUpdate: NetworkInfoUpdateHandler?) {
        let notifer: () -> Void = { [weak self] in
            DispatchQueue.main.async {
                onNetworkInfoDidUpdate?(self?.currentSIMs ?? [])
            }
        }

        if #available(iOS 12.0, *) {
            serviceSubscriberCellularProvidersDidUpdateNotifier = { _ in notifer() }
        } else {
            subscriberCellularProviderDidUpdateNotifier = { _ in notifer() }
        }
    }
}

#if DEBUG

class MockATTNetworkInfoProvider: MobileNetworkInfoProvider {
    let currentSIMs: [SIMInfo] = [SIMInfo(mcc: "310", mnc: "007")]
    var onNetworkInfoDidUpdate: NetworkInfoUpdateHandler?
    func subscribeToNetworkInfoChanges(onNetworkInfoDidUpdate: NetworkInfoUpdateHandler?) { }
}

#endif

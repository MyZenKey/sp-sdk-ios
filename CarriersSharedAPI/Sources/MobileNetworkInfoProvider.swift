//
//  MobileNetworkInfoProvider.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/21/19.
//  Copyright © 2018 XCI JV, LLC. All rights reserved.
//

import Foundation
import CoreTelephony

protocol MobileNetworkInfoProvider: class {
    var carriersForCurrentSIMs: [CTCarrier] { get }

    func subscribeToNetworkInfoChanges(onNetworkInfoDidUpdate: (() -> Void)?)
}

extension CTTelephonyNetworkInfo: MobileNetworkInfoProvider {
    var carriersForCurrentSIMs: [CTCarrier] {
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
        return simCarriers
    }

    func subscribeToNetworkInfoChanges(onNetworkInfoDidUpdate: (() -> Void)?) {
        if #available(iOS 12.0, *) {
            serviceSubscriberCellularProvidersDidUpdateNotifier = { _ in
                onNetworkInfoDidUpdate?()
            }
        } else {
            subscriberCellularProviderDidUpdateNotifier = { _ in
                onNetworkInfoDidUpdate?()
            }
        }
    }
}

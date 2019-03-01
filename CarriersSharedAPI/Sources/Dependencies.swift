//
//  Dependencies.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/28/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
import CoreTelephony

protocol DependenciesProtocol {
    var carrierInfoService: CarrierInfoServiceProtocol { get }
    var discoveryService: DiscoveryServiceProtocol { get }
    var openIdService: OpenIdServiceProtocol { get }
}

class Dependencies: DependenciesProtocol {
    let carrierInfoService: CarrierInfoServiceProtocol = CarrierInfoService(
        mobileNetworkInfoProvder: CTTelephonyNetworkInfo()
    )

    private(set) lazy var discoveryService: DiscoveryServiceProtocol = DiscoveryService(
        networkService: NetworkService(),
        carrierInfoService: carrierInfoService
    )

    let openIdService: OpenIdServiceProtocol = OpenIdService()
}

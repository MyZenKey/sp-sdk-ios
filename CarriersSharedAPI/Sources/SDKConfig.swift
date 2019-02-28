//
//  SDKConfig.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/19/19.
//  Copyright © 2018 XCI JV, LLC. ALL RIGHTS RESERVED.
//

import Foundation
import CoreTelephony

protocol SDKConfigProtocol {
    var clientId: String { get }
    var redirectURI: String { get }
    var carrierInfoService: CarrierInfoServiceProtocol { get }
    var discoveryService: DiscoveryServiceProtocol { get }
    var openIdService: OpenIdServiceProtocol { get }
}

class SDKConfig {
    enum PlistKeys {
        static let ClientId = "ProjectVerifyClientId"
    }

    // MARK: - static properties
    // these should be loaded at app launch and not be mutated for the lifetime of the application
    public private(set) var isLoaded: Bool = false
    public private(set) var clientId: String!
    private(set) var redirectURI: URL!

    private let carrierInfoService: CarrierInfoServiceProtocol = CarrierInfoService(
        mobileNetworkInfoProvder: CTTelephonyNetworkInfo()
    )

    // MARK: - dynamic properties
    // these are volatile based on the sim state and network and should be fetched just in time
    // for up-to-date requests:

    private(set) lazy var discoveryService: DiscoveryServiceProtocol = DiscoveryService(
        networkService: NetworkService(),
        carrierInfoService: carrierInfoService
    )

    let openIdService: OpenIdServiceProtocol = OpenIdService()

    func loadFromBundle(bundle: Bundle) {
        defer { isLoaded = true }
        guard
            let clientId = bundle.object(forInfoDictionaryKey: PlistKeys.ClientId) as? String else {
                fatalError("""
                    Please configure the following key in your App's info plist:
                    \(PlistKeys.ClientId)
                    """)
        }

        // TODO: define project verify unique id based bundle url scheme and ask client to specify it
        // pull from plist here:
        guard
            // TODO: heuristic for finiding a "correct" url scheme
            let redirectScheme = urlSchemesFromBundle(bundle: bundle).first,
            let redirectURI = URL(string: "\(redirectScheme)://code") else {
                fatalError("Project Verify Please configure a corr")
        }

        self.clientId = clientId
        self.redirectURI = redirectURI
    }

    private func assertConfigHasLoaded() {
        guard isLoaded else {
            fatalError("attempting to access Project Verify SDK config before loading")
        }
    }

    private func urlSchemesFromBundle(bundle: Bundle) -> [String] {
        guard
            let urlTypes = bundle.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] else {
                return []
        }
        // extract schems from each url type and flatten them into a single array:
        return urlTypes.compactMap() { type in
            return type["CFBundleURLSchemes"] as? [String]
        }.reduce(into: [String]()) { acc, cur in
            acc.append(contentsOf: cur)
        }
    }
}

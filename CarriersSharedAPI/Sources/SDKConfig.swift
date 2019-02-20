//
//  SDKConfig.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/19/19.
//  Copyright © 2019 Rightpoint. All rights reserved.
//

import Foundation

class SDKConfig {
    enum PlistKeys {
        static let ClientId = "ProjectVerifyClientId"
        static let ClientSecret = "ProjectVerifyClientSecret"
    }

    // MARK: - static properties
    // these should be loaded at app launch and not be mutated for the lifetime of the application
    public private(set) var clientId: String!
    public private(set) var clientSecret: String!
    private(set) var redirectURI: URL!

    // MARK: - dynamic properties
    // these are volitale based on the sim state and network and should be fetched just in time
    // for up-to-date requests:
    let sharedAPI = SharedAPI()
    private(set) var carrierName: String?

    lazy var carrierConfig: [String: Any]? = {
        return sharedAPI.discoverCarrierConfiguration()
    }()

    func loadFromBundle(bundle: Bundle) {

        print(Bundle.main.infoDictionary!)

        guard
            let clientId = bundle.object(forInfoDictionaryKey: PlistKeys.ClientId) as? String,
            let clientSecret = bundle.object(forInfoDictionaryKey: PlistKeys.ClientSecret) as? String else {
                fatalError("""
                    Please configure the following keys in your App's info plist:
                    \(PlistKeys.ClientId), \(PlistKeys.ClientSecret)
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
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI

    }

    private func urlSchemesFromBundle(bundle: Bundle) -> [String] {
        guard
            let urlTypes = bundle.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] else {
                return []
        }
        // extract schems from each url type and flatten them into a single array:
        return urlTypes.compactMap() { type in
            return type["CFBundleURLSchemes"] as? [String];
            }.reduce(into: [String]()) { acc, cur in
                acc.append(contentsOf: cur)
        }
    }
}

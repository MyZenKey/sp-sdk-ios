//
//  SDKConfig.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/19/19.
//  Copyright © 2018 XCI JV, LLC. ALL RIGHTS RESERVED.
//

import Foundation

struct SDKConfig {
    public private(set) var isLoaded: Bool = false
    public private(set) var clientId: String!
    private(set) var redirectURL: URL!

    init() {}

    init(clientId: String, redirectURL: URL) {
        self.clientId = clientId
        self.redirectURL = redirectURL
        self.isLoaded = true
    }
}

struct SDKConfigLoader {
    private enum PlistKeys {
        static let ClientId = "ProjectVerifyClientId"
    }

    static func loadFromBundle(bundle: Bundle) -> SDKConfig {
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
            let redirectScheme = SDKConfigLoader.urlSchemesFromBundle(bundle: bundle).first,
            let redirectURL = URL(string: "\(redirectScheme)://code") else {
                fatalError("Project Verify Please configure a corr")
        }


        return SDKConfig(clientId: clientId, redirectURL: redirectURL)
    }

    private static func urlSchemesFromBundle(bundle: Bundle) -> [String] {
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

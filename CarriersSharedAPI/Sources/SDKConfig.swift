//
//  SDKConfig.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/19/19.
//  Copyright © 2018 XCI JV, LLC. ALL RIGHTS RESERVED.
//

import Foundation

public enum BundleLoadingErrors: Error, Equatable {
    case specifyClientId
    case specifyRedirectURLScheme
}

struct SDKConfig: Equatable {
    public private(set) var isLoaded: Bool = false
    public private(set) var clientId: String!
    private(set) var redirectURL: URL!

    init() {}

    init(clientId: String, redirectURL: URL) {
        self.clientId = clientId
        self.redirectURL = redirectURL
        self.isLoaded = true
    }

    static func load(fromBundle bundle: ProjectVerifyBundleProtocol) throws -> SDKConfig {
        guard let clientId = bundle.clientId else {
            throw BundleLoadingErrors.specifyClientId
        }

        let redirectScheme = "xci\(clientId)"
        guard bundle.urlSchemes.contains(redirectScheme) else {
            throw BundleLoadingErrors.specifyRedirectURLScheme
        }

        let redirectURL = URL(string: "\(redirectScheme)://code")!
        return SDKConfig(clientId: clientId, redirectURL: redirectURL)
    }
}

protocol ProjectVerifyBundleProtocol {
    var clientId: String? { get }
    var urlSchemes: [String] { get }
}

private enum PlistKeys {
    static let ClientId = "ProjectVerifyClientId"
    static let BundleURLTypes = "CFBundleURLTypes"
}

extension Bundle: ProjectVerifyBundleProtocol {
    var clientId: String? {
        return object(forInfoDictionaryKey: PlistKeys.ClientId) as? String
    }

    var urlSchemes: [String] {
        guard
            let urlTypes = object(forInfoDictionaryKey: PlistKeys.BundleURLTypes) as? [[String: Any]] else {
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

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

    private static let defaultHost = "projectverify"

    public private(set) var isLoaded: Bool = false
    public private(set) var clientId: String!
    private(set) var redirectScheme: String!
    private(set) var redirectHost: String!

    init() {}

    init(clientId: String,
         redirectScheme: String,
         redirectHost: String = SDKConfig.defaultHost) {
        self.clientId = clientId
        self.isLoaded = true
        self.redirectScheme = redirectScheme
        self.redirectHost = redirectHost
    }

    static func load(fromBundle bundle: ProjectVerifyBundleProtocol) throws -> SDKConfig {
        guard let clientId = bundle.clientId else {
            throw BundleLoadingErrors.specifyClientId
        }

        let redirectScheme: String
        if let customURLScheme = bundle.customURLScheme {
            redirectScheme = customURLScheme
        } else {
            redirectScheme = "\(clientId)"
        }

        let redirectHost: String
        if let customURLHost = bundle.customURLHost {
            redirectHost = customURLHost
        } else {
            redirectHost = SDKConfig.defaultHost
        }

        guard bundle.urlSchemes.contains(redirectScheme) ||
            redirectScheme == "http" ||
            redirectScheme == "https" else {
            throw BundleLoadingErrors.specifyRedirectURLScheme
        }

        return SDKConfig(
            clientId: clientId,
            redirectScheme: redirectScheme,
            redirectHost: redirectHost
        )
    }
}

extension SDKConfig {
    func redirectURL(forRoute route: Route) -> URL {
        return URL(string: "\(redirectScheme!)://\(redirectHost!)\(route.rawValue)")!
    }
}

protocol ProjectVerifyBundleProtocol {
    var clientId: String? { get }
    var urlSchemes: [String] { get }
    var customURLScheme: String? { get }
    var customURLHost: String? { get }
}

private enum PlistKeys: String {
    case clientId = "ProjectVerifyClientId"
    case customScheme = "ProjectVerifyCustomScheme"
    case customHost = "ProjectVerifyCustomHost"
    case bundleURLTypes = "CFBundleURLTypes"
}

extension Bundle: ProjectVerifyBundleProtocol {
    var clientId: String? {
        return object(forInfoDictionaryKey: PlistKeys.clientId.rawValue) as? String
    }

    var customURLScheme: String? {
        return object(forInfoDictionaryKey: PlistKeys.customScheme.rawValue) as? String
    }

    var customURLHost: String? {
        return object(forInfoDictionaryKey: PlistKeys.customHost.rawValue) as? String
    }

    var urlSchemes: [String] {
        guard
            let urlTypes = object(forInfoDictionaryKey: PlistKeys.bundleURLTypes.rawValue) as? [[String: Any]] else {
                return []
        }

        // extract schemes from each url type and flatten them into a single array:
        return urlTypes.compactMap() { type in
            return type["CFBundleURLSchemes"] as? [String]
            }.reduce(into: [String]()) { acc, cur in
                acc.append(contentsOf: cur)
        }
    }
}

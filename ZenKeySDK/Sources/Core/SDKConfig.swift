//
//  SDKConfig.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/19/19.
//  Copyright © 2019 ZenKey, LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

public enum BundleLoadingErrors: Error, Equatable {
    case specifyClientId
    case specifyRedirectURLScheme
}

struct SDKConfig: Equatable {
    enum Default: String {
        case host = "com.xci.provider.sdk"
        case path = ""
    }

    public private(set) var isLoaded: Bool = false
    public private(set) var clientId: String!
    private(set) var redirectScheme: String!
    private(set) var redirectHost: String!
    private(set) var redirectPath: String!

    init() {}

    init(clientId: String,
         redirectScheme: String,
         redirectHost: String = Default.host.rawValue,
         redirectPath: String = Default.path.rawValue) {
        self.clientId = clientId
        self.isLoaded = true
        self.redirectScheme = redirectScheme
        self.redirectHost = redirectHost
        self.redirectPath = redirectPath
    }

    static func load(fromBundle bundle: ZenKeyBundleProtocol) throws -> SDKConfig {
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
            redirectHost = Default.host.rawValue
        }

        let redirectPath: String
        if let customURLPath = bundle.customURLPath {
            redirectPath = customURLPath
        } else {
            redirectPath = Default.path.rawValue
        }

        guard bundle.urlSchemes.contains(redirectScheme) ||
            redirectScheme == "http" ||
            redirectScheme == "https" else {
            throw BundleLoadingErrors.specifyRedirectURLScheme
        }

        return SDKConfig(
            clientId: clientId,
            redirectScheme: redirectScheme,
            redirectHost: redirectHost,
            redirectPath: redirectPath
        )
    }
}

extension SDKConfig {
    var redirectURL: URL {
        return URL(string: "\(redirectScheme!)://\(redirectHost!)\(redirectPath!)")!
    }
}

protocol ZenKeyBundleProtocol {
    var clientId: String? { get }
    var urlSchemes: [String] { get }
    var customURLScheme: String? { get }
    var customURLHost: String? { get }
    var customURLPath: String? { get }
}

private enum PlistKeys: String {
    case clientId = "ZenKeyClientId"
    case customScheme = "ZenKeyCustomScheme"
    case customHost = "ZenKeyCustomHost"
    case customPath = "ZenKeyCustomPath"
    case bundleURLTypes = "CFBundleURLTypes"
}

extension Bundle: ZenKeyBundleProtocol {
    var clientId: String? {
        return object(forInfoDictionaryKey: PlistKeys.clientId.rawValue) as? String
    }

    var customURLScheme: String? {
        return object(forInfoDictionaryKey: PlistKeys.customScheme.rawValue) as? String
    }

    var customURLHost: String? {
        return object(forInfoDictionaryKey: PlistKeys.customHost.rawValue) as? String
    }

    var customURLPath: String? {
        return object(forInfoDictionaryKey: PlistKeys.customPath.rawValue) as? String
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

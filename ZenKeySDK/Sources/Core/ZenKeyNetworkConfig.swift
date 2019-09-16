//
//  ZenKeyNetworkConfig.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 4/16/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

struct ZenKeyNetworkConfig {

    let scheme = "https"

    enum Host: String {
        case staging = "app.myzenkey.com"
        // swiftlint:disable:next identifier_name
        case qa = "discoveryissuer-qa.myzenkey.com"
        case production = "discoveryissuer.myzenkey.com"
    }

    let host: Host

    init(host: Host) {
        self.host = host
    }

    func resource(forPath path: String, queryItems: [String: String] = [:]) -> URL {
        var components = URLComponents()
        components.scheme = scheme

        #if DEBUG
        components.host = host.rawValue
        #else
        components.host = Host.production.rawValue
        #endif

        components.path = path
        components.queryItems = queryItems.map { return URLQueryItem(name: $0.key, value: $0.value) }

        guard let resource = components.url else {
            fatalError("invalid resource: \(components) produces no url")
        }

        return resource
    }
}

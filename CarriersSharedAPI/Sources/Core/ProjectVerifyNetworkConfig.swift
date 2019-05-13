//
//  ProjectVerifyNetworkConfig.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 4/16/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

struct ProjectVerifyNetworkConfig {

    let scheme = "https"

    enum Host: String {
        #if DEBUG
        case staging = "app.xcijv.com"
        // swiftlint:disable:next identifier_name
        case qa = "discoveryissuer-qa.xcijv.com"
        #endif
        case production = "discoveryissuer.xcijv.com"
    }

    let host: Host

    init(host: Host) {
        self.host = host
    }

    func resource(forPath path: String, queryItems: [String: String] = [:]) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host.rawValue
        components.path = path

        components.queryItems = queryItems.map { return URLQueryItem(name: $0.key, value: $0.value) }

        guard let resource = components.url else {
            fatalError("invalid resource: \(components) produces no url")
        }

        return resource
    }
}

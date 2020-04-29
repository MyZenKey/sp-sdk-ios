//
//  ZenKeyNetworkConfig.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 4/16/19.
//  Copyright © 2019-2020 ZenKey, LLC.
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

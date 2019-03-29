//
//  OpenIdConfig.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 3/29/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

struct OpenIdConfig: Equatable {
    let tokenEndpoint: URL
    let authorizationEndpoint: URL
    let issuer: URL
    
    init(tokenEndpoint: URL,
         authorizationEndpoint: URL,
         issuer: URL) {
        self.tokenEndpoint = tokenEndpoint
        self.authorizationEndpoint = authorizationEndpoint
        self.issuer = issuer
    }
}

extension OpenIdConfig: Decodable {
    enum CodingKeys: String, CodingKey {
        case tokenEndpoint = "token_endpoint"
        case authorizationEndpoint = "authorization_endpoint"
        case issuer
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        tokenEndpoint = try values.decode(URL.self, forKey: .tokenEndpoint)
        authorizationEndpoint = try values.decode(URL.self, forKey: .authorizationEndpoint)
        issuer = try values.decode(URL.self, forKey: .issuer)
    }
}

enum OpenIdConfigResult {
    case config(OpenIdConfig)
    case error(String)
}

extension OpenIdConfigResult: Decodable {
    enum CodingKeys: String, CodingKey {
        case error
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        do {
            let error = try values.decode(String.self, forKey: .error)
            self = .error(error)
        } catch {
            self = .config(try OpenIdConfig(from: decoder))
        }
    }
}

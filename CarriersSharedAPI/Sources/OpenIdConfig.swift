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
}

/// an error originating within the issuer service and returned via a successful HTTP response.
struct OpenIdIssuerError {
    let error: String
    let errorDescription: String?
}

extension OpenIdIssuerError: Decodable {
    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
    }
}

/// The result context when retrieving an `OpenIdConfig` from the discovery endpoint. The HTTP body
/// will contain either a valid configuration or an error string.
enum OpenIdConfigResult {
    case config(OpenIdConfig)
    case error(OpenIdIssuerError)
}

extension OpenIdConfigResult: Decodable {
    init(from decoder: Decoder) throws {
        do {
            self = .config(try OpenIdConfig(from: decoder))
        } catch {
            self = .error(try OpenIdIssuerError(from: decoder))
        }
    }
}

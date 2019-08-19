//
//  OpenIdConfig.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 3/29/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

struct OpenIdConfig: Equatable {
    /// The authorization enpdoint to issue authroization requests to.
    let authorizationEndpoint: URL
    /// The open id issuer.
    let issuer: URL
    /// A string the carrier can provide to enable per carrier branding of the Login with CCID
    /// button. Examples might be "Powered by AT&T" etc.
    let linkBranding: String?
    ///
    let linkImage: URL?
    ///
    let branding: URL?

    init(authorizationEndpoint: URL,
         issuer: URL) {
        self.authorizationEndpoint = authorizationEndpoint
        self.issuer = issuer
        self.linkBranding = nil
        self.linkImage = nil
        self.branding = nil
    }
}

extension OpenIdConfig: Decodable {
    enum CodingKeys: String, CodingKey {
        case authorizationEndpoint = "authorization_endpoint"
        case issuer
        case linkBranding = "link_branding"
        case linkImage = "link_image"
        case branding
    }
}

/// The result context when retrieving an `OpenIdConfig` from the discovery endpoint. The HTTP body
/// will contain either a valid configuration or an error string.
enum IssuerResponse {
    /// an error originating within the issuer service and returned via a successful HTTP response.
    struct Redirect {
        let error: String
        let redirectURI: URL
    }

    /// An error originating within the issuer service and returned via a successful HTTP response.
    struct Error {
        let error: String
        let errorDescription: String?
    }

    case config(CarrierConfig)
    case redirect(Redirect)
    case error(Error)
}

struct DiscoverySimInfo {
    let simInfo: SIMInfo
}

extension DiscoverySimInfo: Decodable {
    enum CodingKeys: String, CodingKey {
        case mccmnc
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let mccmncNumericValue = try container.decode(Int.self, forKey: .mccmnc)
        let mccmnc = String(mccmncNumericValue)
        let simInfoResult =  mccmnc.toSIMInfo()
        switch simInfoResult {
        case .value(let simInfo):
            self = DiscoverySimInfo(simInfo: simInfo)
        case .error(let error):
            throw error
        }
    }
}

extension IssuerResponse: Decodable {
    init(from decoder: Decoder) throws {
        if  let config = try? OpenIdConfig(from: decoder),
            let discoverdSIMInfo = try? DiscoverySimInfo(from: decoder) {
            self = .config(CarrierConfig(simInfo: discoverdSIMInfo.simInfo, openIdConfig: config))
        } else if let redirect = try? Redirect(from: decoder) {
            self = .redirect(redirect)
        } else {
            // throw out if no error
            self = .error(try Error(from: decoder))
        }
    }
}

extension IssuerResponse.Redirect: Decodable {
    enum CodingKeys: String, CodingKey {
        case error
        case redirectURI = "redirect_uri"
    }
}

extension IssuerResponse.Error: Decodable {
    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
    }
}

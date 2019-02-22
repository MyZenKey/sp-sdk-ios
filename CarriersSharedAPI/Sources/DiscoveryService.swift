//
//  SharedAPI.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/21/19.
//  Copyright © 2018 XCI JV, LLC. All rights reserved.
//

import UIKit
import Foundation

struct CarrierConfig {
    let carrier: Carrier
    let openIdConfig: OpenIdConfig
}

// TODO: strongly type this
typealias OpenIdConfig = [String: String]

enum DiscoveryServiceResult {
    case knownMobileNetwork(CarrierConfig)
    case unknownMobileNetwork
    case noMobileNetwork
    case error(Error)
}

protocol DiscoveryServiceProtocol {
    func discoverConfig(completion: @escaping (DiscoveryServiceResult) -> Void)
}

class DiscoveryService: DiscoveryServiceProtocol {
    private let carrierInfoService: CarrierInfoServiceProtocol
    private let discoveryEndpointFormat = "https://100.25.175.177/.well-known/openid_configuration?config=false&mcc=%@&mnc=%@"
    private var discoveryEndpoint: String? {
        guard let sim = carrierInfoService.primarySIM else { return nil }
        return String(format: discoveryEndpointFormat, sim.identifiers.mcc, sim.identifiers.mnc)
    }

    private var configuration: OpenIdConfig?

    init(carrierInfoService: CarrierInfoServiceProtocol) {
        self.carrierInfoService = carrierInfoService
    }

    func discoverConfig(completion: @escaping (DiscoveryServiceResult) -> Void) {
        guard let sim = carrierInfoService.primarySIM else {
            completion(.noMobileNetwork)
            return
        }

        openIdConfig(forCarrier: sim.carrier) { openIdConfig, error in
            guard error == nil else {
                completion(.error(error!))
                return
            }

            guard let openIdConfig = openIdConfig else {
                completion(.unknownMobileNetwork)
                return
            }


            let config = CarrierConfig(carrier: sim.carrier, openIdConfig: openIdConfig)
            completion(.knownMobileNetwork(config))
        }
    }

    private func openIdConfig(forCarrier carrier: Carrier,
                              completion: @escaping (OpenIdConfig?, Error?) -> Void ) {

        // TODO: business rules about what takes precedence here

        // if we have a configuration locally, return that:
        guard configuration == nil else {
            completion(configuration, nil)
            return
        }

        // if not, check the hard coded values (future will be a more robust cache):
        let shortName = carrier.shortName.rawValue
        guard discoveryData[shortName] == nil else {
            completion(discoveryData[shortName], nil)
            return
        }

        // last resort – go over the network again:

        performDiscovery(completion: completion)
    }

    //this function will perform a backup discovery
    private func performDiscovery(completion: ((OpenIdConfig?, Error?) -> Void)?) {

        guard
            let discoveryURLString = discoveryEndpoint,
            let discoveryURL = URL(string: discoveryURLString) else {
            return
        }

        print("Performing primary discovery lookup")
        var request = URLRequest(url: discoveryURL)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, rawResponse, error) in
            print("Discovery Information has returned")

            guard let sself = self else { return }
            guard
                error == nil,
                let data = data,
                let responseString = String(data: data, encoding:String.Encoding.utf8),
                let json = responseString.data(using: String.Encoding.utf8) else {
                sself.configuration = nil
                completion?(nil, error)
                return
            }

            print(responseString)
            let jsonDocument:JsonDocument = JsonDocument(data: json)
            let config = [
                "scopes_supported": "openid email profile",
                "response_types_supported": "code",
                "userinfo_endpoint": jsonDocument["userinfo_endpoint"].toString!,
                "token_endpoint": jsonDocument["token_endpoint"].toString!,
                "authorization_endpoint": jsonDocument["authorization_endpoint"].toString!,
                "issuer": jsonDocument["issuer"].toString!
            ]

            sself.configuration = config

            completion?(config, nil)

        }
        task.resume()
    }

    // TODO: this data should be pulled from a cache and updated according to some schedule
    private let discoveryData = [
        "tmo": [
            "scopes_supported": "openid email profile",
            "response_types_supported": "code",
            "userinfo_endpoint": "https://iam.msg.t-mobile.com/oidc/v1/userinfo",
            "token_endpoint": "https://brass.account.t-mobile.com/tms/v3/usertoken",
            "authorization_endpoint": "https://account.t-mobile.com/oauth2/v1/auth",
            "issuer": "https://ppd.account.t-mobile.com"
        ],
        "vzw": [
            "scopes_supported": "openid email profile",
            "response_types_supported": "code",
            "userinfo_endpoint": "https://api.yourmobileid.com:22790/userinfo",
            "token_endpoint": "https://auth.svcs.verizon.com:22790/vzconnect/token",
            "authorization_endpoint": "https://auth.svcs.verizon.com:22790/vzconnect/authorize",
            "issuer": "https://auth.svcs.verizon.com"
        ],
        "att": [
            "scopes_supported": "email zipcode name phone",
            "response_types_supported": "code",
            "userinfo_endpoint": "https://oidc.test.xlogin.att.com/mga/sps/oauth/oauth20/userinfo",
            "token_endpoint": "https://oidc.test.xlogin.att.com/mga/sps/oauth/oauth20/token",
            "authorization_endpoint": "https://oidc.test.xlogin.att.com/mga/sps/oauth/oauth20/authorize",
            "issuer": "https://oidc.test.xlogin.att.com"
        ]
    ]
}

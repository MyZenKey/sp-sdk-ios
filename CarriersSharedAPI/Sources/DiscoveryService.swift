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

extension DiscoveryServiceResult {
    var carrierConfig: CarrierConfig? {
        switch self {
        case .knownMobileNetwork(let config):
            return config
        default:
            return nil
        }
    }

    var errorValue: Error? {
        switch self {
        case .error(let error):
            return error
        default:
            return nil
        }
    }
}

struct DiscoveryEndpointError: Error {
    let errorString: String
}

protocol DiscoveryServiceProtocol {
    func discoverConfig(completion: @escaping (DiscoveryServiceResult) -> Void)
}

class DiscoveryService: DiscoveryServiceProtocol {
    private let carrierInfoService: CarrierInfoServiceProtocol
    private let networkService: NetworkServiceProtocol

//    Issuer –
//    IP - https://100.25.175.177/.well-known/openid_configuration
//    FQDN - https://app.xcijv.com/.well-known/openid_configuration
//    UI –
//    IP – https://23.20.110.44
//    FQDN – https://app.xcijv.com/ui
    private let discoveryEndpointFormat = "https://100.25.175.177/.well-known/openid_configuration?config=false&mcc=%@&mnc=%@"

    private var configuration: OpenIdConfig?

    init(networkService: NetworkServiceProtocol,
         carrierInfoService: CarrierInfoServiceProtocol) {
        self.networkService = networkService
        self.carrierInfoService = carrierInfoService
    }

    func discoverConfig(completion: @escaping (DiscoveryServiceResult) -> Void) {
        guard let sim = carrierInfoService.primarySIM else {
            completion(.noMobileNetwork)
            return
        }

        openIdConfig(forSIMInfo: sim) { [weak self] openIdConfig, error in
            guard error == nil else {
                if let fallBackConfig = self?.recoverFromCache(carrier: sim.carrier,
                                                               allowStaleRecords: true) {
                    let config = CarrierConfig(carrier: sim.carrier,
                                               openIdConfig: fallBackConfig)
                    completion(.knownMobileNetwork(config))
                } else {
                    completion(.error(error!))
                }
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

    private func openIdConfig(forSIMInfo simInfo: SIMInfo,
                              completion: @escaping (OpenIdConfig?, Error?) -> Void ) {

        // TODO: business rules about what takes precedence here

        // if we have a configuration locally, return that:
        guard configuration == nil else {
            completion(configuration, nil)
            return
        }


        // if not, check the hard coded values (future will be a more robust cache):
        let cachedConfig = recoverFromCache(carrier: simInfo.carrier)
        guard cachedConfig == nil else {
            completion(cachedConfig!, nil)
            return
        }

        // last resort – go over the network again:
        performDiscovery(forSIMInfo: simInfo, completion: completion)
    }

    private func recoverFromCache(carrier: Carrier,
                                  allowStaleRecords: Bool = false) -> OpenIdConfig? {

        guard allowStaleRecords else {
            return nil
        }
        // TODO: real caching service
        return discoveryData[carrier.shortName.rawValue]
    }

    private func performDiscovery(forSIMInfo simInfo: SIMInfo,
                                  completion: ((OpenIdConfig?, Error?) -> Void)?) {

        let endpointString = discoveryEndpoint(forSIMInfo: simInfo)
        guard let discoveryURL = URL(string: endpointString) else {
            fatalError("disocvery endpoint is returning an invalid url: \(endpointString)")
        }

        print("Performing primary discovery lookup")
        var request = URLRequest(url: discoveryURL)
        request.httpMethod = "GET"

        networkService.requestJSON(request: request) { [weak self] jsonDocument, error in
            guard
                error == nil,
                let jsonDocument = jsonDocument else {
                self?.configuration = nil
                completion?(nil, error)
                return
            }


            // TODO: currently a query for unknown mcc/mnc returns an error. we may want to parse
            // this out further in the case we want to follow the returned redirect, etc.
            guard !jsonDocument["error"].exists else {
                let errorString = jsonDocument["error"].toString!
                completion?(nil, DiscoveryEndpointError(errorString: errorString))
                return
            }

            let config = [
                "scopes_supported": "openid email profile",
                "response_types_supported": "code",
                "userinfo_endpoint": jsonDocument["userinfo_endpoint"].toString!,
                "token_endpoint": jsonDocument["token_endpoint"].toString!,
                "authorization_endpoint": jsonDocument["authorization_endpoint"].toString!,
                "issuer": jsonDocument["issuer"].toString!
            ]

            self?.configuration = config
            completion?(config, nil)
        }
    }

    private func discoveryEndpoint(forSIMInfo simInfo: SIMInfo) -> String {
        return String(
            format: discoveryEndpointFormat,
            simInfo.identifiers.mcc,
            simInfo.identifiers.mnc
        )
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

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
    let simInfo: SIMInfo
    let carrier: Carrier
    let openIdConfig: OpenIdConfig
}

// TODO: strongly type this
typealias OpenIdConfig = [String: String]

enum DiscoveryServiceResult {
    case knownMobileNetwork(CarrierConfig)
    case unknownMobileNetwork
    case noMobileNetwork
    case error(DiscoveryServiceError)
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

    var errorValue: DiscoveryServiceError? {
        switch self {
        case .error(let error):
            return error
        default:
            return nil
        }
    }
}

enum DiscoveryServiceError: Error {
    case issuerError(String)
    case networkError(Error)
}

protocol DiscoveryServiceProtocol {
    func discoverConfig(completion: @escaping (DiscoveryServiceResult) -> Void)
}

class DiscoveryService: DiscoveryServiceProtocol {

    typealias OpenIdResult = Result<OpenIdConfig, DiscoveryServiceError>

    private let carrierInfoService: CarrierInfoServiceProtocol
    private let networkService: NetworkServiceProtocol

//    Issuer –
//    IP - https://100.25.175.177/.well-known/openid_configuration
//    FQDN - https://app.xcijv.com/.well-known/openid_configuration
//    UI –
//    IP – https://23.20.110.44
//    FQDN – https://app.xcijv.com/ui
    private let discoveryEndpointFormat = "http://100.25.175.177/.well-known/openid_configuration?config=false&mcc=%@&mnc=%@"
//    private let discoveryEndpointFormat = "https://100.25.175.177/.well-known/openid_configuration?config=false&mcc=%@&mnc=%@"

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

        let carrier = sim.carrier(usingCarrierLookUp: NetworkIdentifierCache.bundledCarrierLookup)

        openIdConfig(forSIMInfo: sim, carrier: carrier) { [weak self] result in

            switch result {
            case .value(let openIdConfig):
                let config = CarrierConfig(
                    simInfo: sim,
                    carrier: carrier,
                    openIdConfig: openIdConfig)
                completion(.knownMobileNetwork(config))

            case .error(let error):
                if let fallBackConfig = self?.recoverFromCache(carrier: carrier,
                                                               allowStaleRecords: true) {
                    let config = CarrierConfig(
                        simInfo: sim,
                        carrier: carrier,
                        openIdConfig: fallBackConfig)
                    completion(.knownMobileNetwork(config))
                } else {
                    completion(.error(error))
                }
            }
        }
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
            "authorization_endpoint": "xci://authorize",
//            "authorization_endpoint": "https://oidc.test.xlogin.att.com/mga/sps/oauth/oauth20/authorize",
            "issuer": "https://oidc.test.xlogin.att.com"
        ]
    ]
}

private extension DiscoveryService {
    func openIdConfig(forSIMInfo simInfo: SIMInfo,
                      carrier: Carrier,
                      completion: @escaping (OpenIdResult) -> Void ) {

        // TODO: business rules about what takes precedence here

        // if we have a configuration locally, return that:
        guard configuration == nil else {
            completion(OpenIdResult.value(configuration!))
            return
        }

        // if not, check the hard coded values (future will be a more robust cache):
        let cachedConfig = recoverFromCache(carrier: carrier)
        guard cachedConfig == nil else {
            completion(OpenIdResult.value(cachedConfig!))
            return
        }

        // last resort – go over the network again:
        performDiscovery(forSIMInfo: simInfo, completion: completion)
    }
    
    func recoverFromCache(carrier: Carrier,
                                  allowStaleRecords: Bool = false) -> OpenIdConfig? {

        guard allowStaleRecords else {
            return nil
        }
        // TODO: real caching service
        return discoveryData[carrier.shortName]
    }

    func performDiscovery(forSIMInfo simInfo: SIMInfo,
                                  completion: ((OpenIdResult) -> Void)?) {

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
                    completion?(
                        OpenIdResult.error(DiscoveryServiceError.networkError(error ?? UnknownError()))
                    )
                    return
            }

            // TODO: currently a query for unknown mcc/mnc returns an error. we may want to parse
            // this out further in the case we want to follow the returned redirect, etc.
            guard !jsonDocument["error"].exists else {
                let errorString = jsonDocument["error"].toString!
                completion?(OpenIdResult.error(DiscoveryServiceError.issuerError(errorString)))
                return
            }

            // NOTE: adding this nested config key becuase that's the way the response is structured
            // at the moment – from my understanding it will be removed at some future point
            let config = [
                "scopes_supported": "openid email profile",
                "response_types_supported": "code",
                "userinfo_endpoint": jsonDocument["config"]["userinfo_endpoint"].toString!,
                "token_endpoint": jsonDocument["config"]["token_endpoint"].toString!,
                "authorization_endpoint": "xci://authorize",
//                "authorization_endpoint": jsonDocument["config"]["authorization_endpoint"].toString!,
                "issuer": jsonDocument["config"]["issuer"].toString!
            ]

            self?.configuration = config
            completion?(OpenIdResult.value(config))
        }
    }

    func discoveryEndpoint(forSIMInfo simInfo: SIMInfo) -> String {
        return String(
            format: discoveryEndpointFormat,
            simInfo.mcc,
            simInfo.mnc
        )
    }
}

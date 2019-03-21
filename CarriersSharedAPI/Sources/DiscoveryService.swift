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
    private let configCacheService: ConfigCacheServiceProtocol

//    Issuer –
//    IP - https://100.25.175.177/.well-known/openid_configuration
//    FQDN - https://app.xcijv.com/.well-known/openid_configuration
//    UI –
//    IP – https://23.20.110.44
//    FQDN – https://app.xcijv.com/ui
    private let discoveryEndpointFormat = "http://100.25.175.177/.well-known/openid_configuration?config=false&mcc=%@&mnc=%@"
//    private let discoveryEndpointFormat = "https://100.25.175.177/.well-known/openid_configuration?config=false&mcc=%@&mnc=%@"
    
    private let networkIdentifierCache = NetworkIdentifierCache.bundledCarrierLookup

    init(networkService: NetworkServiceProtocol,
         carrierInfoService: CarrierInfoServiceProtocol,
         configCacheService: ConfigCacheServiceProtocol) {
        self.networkService = networkService
        self.carrierInfoService = carrierInfoService
        self.configCacheService = configCacheService
    }

    func discoverConfig(completion: @escaping (DiscoveryServiceResult) -> Void) {
        guard let sim = carrierInfoService.primarySIM else {
            completion(.noMobileNetwork)
            return
        }

        let carrier = sim.carrier(usingCarrierLookUp: networkIdentifierCache)

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
}

private extension DiscoveryService {
    func openIdConfig(forSIMInfo simInfo: SIMInfo,
                      carrier: Carrier,
                      completion: @escaping (OpenIdResult) -> Void ) {

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
        return configCacheService.config(forIdentifier: carrier.shortName,
                                         allowStaleRecords: allowStaleRecords)
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


            defer { completion?(OpenIdResult.value(config)) }
            guard let sself = self else {
                return
            }
            
            let shortName = simInfo.carrier(usingCarrierLookUp: sself.networkIdentifierCache).shortName
            sself.configCacheService.cacheConfig(
                config,
                forIdentifier: shortName
            )
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

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
    let openIdConfig: OpenIdConfig
}

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
    /// Perofrms carrier discovery using the `CarrierInfoService` with which the `DiscoveryService`
    /// was instantiated.
    ///
    /// This method must always execute the provide closure on the MainThread.
    /// - Parameter completion: the closure invoked with the result of the Discovery.
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
    
    init(networkService: NetworkServiceProtocol,
         carrierInfoService: CarrierInfoServiceProtocol,
         configCacheService: ConfigCacheServiceProtocol) {
        self.networkService = networkService
        self.carrierInfoService = carrierInfoService
        self.configCacheService = configCacheService
    }

    
    /// Perofrms carrier discovery using the `CarrierInfoService` with which the `DiscoveryService`
    /// was instantiated.
    ///
    /// This method must always execute the provide closure on the MainThread.
    /// - Parameter completion: the closure invoked with the result of the Discovery.
    func discoverConfig(completion: @escaping (DiscoveryServiceResult) -> Void) {
        guard let sim = carrierInfoService.primarySIM else {
            DiscoveryService.outcome(.noMobileNetwork, completion: completion)
            return
        }

        openIdConfig(forSIMInfo: sim) { [weak self] result in

            switch result {
            case .value(let openIdConfig):
                let config = CarrierConfig(
                    simInfo: sim,
                    openIdConfig: openIdConfig)
                DiscoveryService.outcome(.knownMobileNetwork(config), completion: completion)
                
            case .error(let error):
                if let fallBackConfig = self?.recoverFromCache(simInfo: sim,
                                                               allowStaleRecords: true) {
                    let config = CarrierConfig(
                        simInfo: sim,
                        openIdConfig: fallBackConfig)
                    DiscoveryService.outcome(.knownMobileNetwork(config), completion: completion)
                } else {
                    DiscoveryService.outcome(.error(error), completion: completion)
                }
            }
        }
    }
}

private extension DiscoveryService {
    /// performs the discovery outcome on the main thread
    static func outcome(
        _ outcome: DiscoveryServiceResult,
        completion: @escaping (DiscoveryServiceResult) -> Void) {
        
        guard !Thread.isMainThread else {
            completion(outcome)
            return
        }
        
        DispatchQueue.main.async {
            completion(outcome)
        }
    }
    
    func openIdConfig(forSIMInfo simInfo: SIMInfo,
                      completion: @escaping (OpenIdResult) -> Void ) {

        let cachedConfig = recoverFromCache(simInfo: simInfo)
        guard cachedConfig == nil else {
            completion(OpenIdResult.value(cachedConfig!))
            return
        }

        // last resort – go over the network again:
        performDiscovery(forSIMInfo: simInfo, completion: completion)
    }
    
    func recoverFromCache(simInfo: SIMInfo,
                          allowStaleRecords: Bool = false) -> OpenIdConfig? {
        return configCacheService.config(forSIMInfo: simInfo,
                                         allowStaleRecords: allowStaleRecords)
    }

    func performDiscovery(forSIMInfo simInfo: SIMInfo,
                                  completion: ((OpenIdResult) -> Void)?) {

        let endpointString = discoveryEndpoint(forSIMInfo: simInfo)
        guard let discoveryURL = URL(string: endpointString) else {
            fatalError("disocvery endpoint is returning an invalid url: \(endpointString)")
        }

        var request = URLRequest(url: discoveryURL)
        request.httpMethod = "GET"
        networkService.requestJSON(
            request: request
        ) { [weak self] (result: Result<OpenIdConfigResult, NetworkServiceError>) in

            switch result {
            case .value(let configResult):
                // Because the endpoint can return either a config _or_ an error, we need to parse the
                // "inner" result and flatten the success or error.
                switch configResult {
                case .config(let openIdConfig):
                    
                    let tempConfig = openIdConfig.withOverwritenAuthURL()
                    
                    self?.configCacheService.cacheConfig(
                        tempConfig, // FIXME: use next line
//                        openIdConfig,
                        forSIMInfo: simInfo
                    )
                    completion?(OpenIdResult.value(tempConfig)) // FIXME: use next line
//                    completion?(OpenIdResult.value(openIdConfig))
                    
                case .error(let errorString):
                    completion?(OpenIdResult.error(DiscoveryServiceError.issuerError(errorString)))
                }
                
            case .error(let error):
                completion?(
                    OpenIdResult.error(DiscoveryServiceError.networkError(error))
                )
            }
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

// FIXME: remove this once we have universal links wired up:
private extension OpenIdConfig {
    /// returns an OID config with auth endpoint overwritten to hard code `xci://`
    func withOverwritenAuthURL() -> OpenIdConfig {
        return OpenIdConfig(
            tokenEndpoint: tokenEndpoint,
            authorizationEndpoint: URL(string: "xci://authorize")!,
            issuer: issuer
        )
    }
}

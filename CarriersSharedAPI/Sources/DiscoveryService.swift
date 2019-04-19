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
    case issuerError(OpenIdIssuerError)
    case networkError(NetworkServiceError)
}

typealias DiscoveryServiceCompletion = (DiscoveryServiceResult) -> Void

protocol DiscoveryServiceProtocol {
    /// Performs carrier discovery using the `CarrierInfoService` with which the `DiscoveryService`
    /// was instantiated.
    ///
    /// This method will always execute the provided closure on the MainThread.
    /// - Parameter completion: the closure invoked with the result of the Discovery.
    func discoverConfig(forSIMInfo simInfo: SIMInfo,
                        completion: @escaping DiscoveryServiceCompletion)
}

class DiscoveryService: DiscoveryServiceProtocol {
    typealias OpenIdResult = Result<OpenIdConfig, DiscoveryServiceError>

    private let networkService: NetworkServiceProtocol
    private let configCacheService: ConfigCacheServiceProtocol

    private let discoveryEndpointFormat = "https://app.xcijv.com/.well-known/openid_configuration?config=false&mcc=%@&mnc=%@"
//    private let discoveryEndpointFormat = "http://100.25.175.177/.well-known/openid_configuration?config=false&mcc=%@&mnc=%@"
    
    init(networkService: NetworkServiceProtocol,
         configCacheService: ConfigCacheServiceProtocol) {
        self.networkService = networkService
        self.configCacheService = configCacheService
    }

    func discoverConfig(forSIMInfo simInfo: SIMInfo,
                        completion: @escaping DiscoveryServiceCompletion) {
        openIdConfig(forSIMInfo: simInfo) { [weak self] result in

            switch result {
            case .value(let openIdConfig):
                let config = CarrierConfig(
                    simInfo: simInfo,
                    openIdConfig: openIdConfig)
                DiscoveryService.outcome(.knownMobileNetwork(config), completion: completion)

            case .error(let error):
                if let fallBackConfig = self?.recoverFromCache(simInfo: simInfo,
                                                               allowStaleRecords: true) {
                    let config = CarrierConfig(
                        simInfo: simInfo,
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
        completion: @escaping DiscoveryServiceCompletion) {
        
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
                    self?.configCacheService.cacheConfig(
                        openIdConfig,
                        forSIMInfo: simInfo
                    )
                    completion?(OpenIdResult.value(openIdConfig))
                    
                case .error(let issuerError):
                    completion?(.error(.issuerError(issuerError)))
                }
                
            case .error(let error):
                completion?(
                    OpenIdResult.error(.networkError(error))
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

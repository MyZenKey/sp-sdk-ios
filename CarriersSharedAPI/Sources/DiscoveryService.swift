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
    /// A carrier valid configuration.
    case knownMobileNetwork(CarrierConfig)
    /// The mobile network is unsupported or couldn't be identified. Seek clarification using
    /// the provided redirect.
    case unknownMobileNetwork(IssuerResponse.Redirect)
    /// An error which occured during the discovery process.
    case error(DiscoveryServiceError)
}

enum DiscoveryServiceError: Error {
    case issuerError(IssuerResponse.Error)
    case networkError(NetworkServiceError)
}

typealias DiscoveryServiceCompletion = (DiscoveryServiceResult) -> Void

protocol DiscoveryServiceProtocol {
    /// Performs carrier discovery for the provided sim info
    ///
    /// This method will always execute the provided closure on the MainThread.
    /// - Parameters:
    ///   - simInfo: the sim info to pass to the discovery service
    ///   - completion: the closure invoked with the result of the Discovery.
    func discoverConfig(forSIMInfo simInfo: SIMInfo?,
                        completion: @escaping DiscoveryServiceCompletion)
}

class DiscoveryService: DiscoveryServiceProtocol {

    private let networkService: NetworkServiceProtocol
    private let configCacheService: ConfigCacheServiceProtocol

    private let discoveryResource = "https://app.xcijv.com/.well-known/openid_configuration"
    private let discoveryEndpointFormat = "%@?&mccmnc=%@%@"

    init(networkService: NetworkServiceProtocol,
         configCacheService: ConfigCacheServiceProtocol) {
        self.networkService = networkService
        self.configCacheService = configCacheService
    }

    func discoverConfig(forSIMInfo simInfo: SIMInfo?,
                        completion: @escaping DiscoveryServiceCompletion) {

        openIdConfig(forSIMInfo: simInfo) { [weak self] result in

            var outcome = result
            // if we have an error, attempt to recover from cache
            if case .error = result {
                // FIXME: this nil sim issue needs to be solved sysemically:
                let simInfo = simInfo ?? SIMInfo(mcc: "999", mnc: "999")

                if let fallBackConfig = self?.recoverFromCache(simInfo: simInfo ,
                                                               allowStaleRecords: true) {
                    let config = CarrierConfig(
                        simInfo: simInfo,
                        openIdConfig: fallBackConfig)

                    outcome = .knownMobileNetwork(config)
                }
            }

            guard !Thread.isMainThread else {
                completion(outcome)
                return
            }

            DispatchQueue.main.async {
                completion(outcome)
            }
        }
    }
}

private extension DiscoveryService {
    func openIdConfig(forSIMInfo simInfo: SIMInfo?,
                      completion: @escaping DiscoveryServiceCompletion) {

        // if we have sim identifers, we can attempt to use the cache:
        if let simInfo = simInfo {
            let cachedConfig = recoverFromCache(simInfo: simInfo)
            guard cachedConfig == nil else {
                completion(.knownMobileNetwork(
                    CarrierConfig(
                        simInfo: simInfo,
                        openIdConfig: cachedConfig!
                    )
                ))
                return
            }
        }

        // last resort – go over the network again:
        performDiscovery(forSIMInfo: simInfo, completion: completion)
    }
    
    func recoverFromCache(simInfo: SIMInfo,
                          allowStaleRecords: Bool = false) -> OpenIdConfig? {
        return configCacheService.config(forSIMInfo: simInfo,
                                         allowStaleRecords: allowStaleRecords)
    }

    func performDiscovery(forSIMInfo simInfo: SIMInfo?,
                          completion: @escaping DiscoveryServiceCompletion) {

        let endpointString = discoveryEndpoint(forSIMInfo: simInfo)
        guard let discoveryURL = URL(string: endpointString) else {
            fatalError("disocvery endpoint is returning an invalid url: \(endpointString)")
        }

        var request = URLRequest(url: discoveryURL)
        request.httpMethod = "GET"
        networkService.requestJSON(
            request: request
        ) { [weak self] (result: Result<IssuerResponse, NetworkServiceError>) in

            switch result {
            case .value(let configResult):
                // Because the endpoint can return either a config _or_ an error, we need to parse the
                // "inner" result and flatten the success or error.
                switch configResult {
                case .config(let openIdConfig):

                    // FIXME: this an invalid place holder sim, we need to solve this null sim
                    // info case systemically.
                    let simInfo = simInfo ?? SIMInfo(mcc: "999", mnc: "999")

                    self?.configCacheService.cacheConfig(
                        openIdConfig,
                        forSIMInfo: simInfo
                    )

                    completion(.knownMobileNetwork(
                        CarrierConfig(
                            simInfo: simInfo,
                            openIdConfig: openIdConfig
                        )
                    ))

                case .redirect(let redirect):
                    completion(.unknownMobileNetwork(redirect))
                    
                case .error(let issuerError):
                    completion(.error(.issuerError(issuerError)))
                }
                
            case .error(let error):
                completion(.error(.networkError(error)))
            }
        }
    }

    func discoveryEndpoint(forSIMInfo simInfo: SIMInfo?) -> String {
        guard let simInfo = simInfo else {
            return discoveryResource
        }

        return String(
            format: discoveryEndpointFormat,
            discoveryResource,
            simInfo.mcc,
            simInfo.mnc
        )
    }
}

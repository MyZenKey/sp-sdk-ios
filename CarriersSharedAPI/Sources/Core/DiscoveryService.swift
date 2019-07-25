//
//  SharedAPI.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/21/19.
//  Copyright © 2018 XCI JV, LLC. All rights reserved.
//

import UIKit
import Foundation

struct CarrierConfig: Equatable {
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
    ///   - simInfo: The sim info to pass to the discovery service
    ///   - prompt: When true, the discovery service will always re-direct the user to the
    ///         discovery-ui experience. The default value is false.
    ///   - completion: The closure invoked with the result of the Discovery.
    func discoverConfig(forSIMInfo simInfo: SIMInfo?,
                        prompt: Bool,
                        completion: @escaping DiscoveryServiceCompletion)
}

class DiscoveryService: DiscoveryServiceProtocol {
    private let sdkConfig: SDKConfig
    private let hostConfig: ProjectVerifyNetworkConfig
    private let networkService: NetworkServiceProtocol
    private let configCacheService: ConfigCacheServiceProtocol

    private let discoveryPath = "/.well-known/openid_configuration"
    private let discoveryEndpointFormat = "%@?&mccmnc=%@%@"

    init(sdkConfig: SDKConfig,
         hostConfig: ProjectVerifyNetworkConfig,
         networkService: NetworkServiceProtocol,
         configCacheService: ConfigCacheServiceProtocol) {
        self.sdkConfig = sdkConfig
        self.hostConfig = hostConfig
        self.networkService = networkService
        self.configCacheService = configCacheService
    }

    func discoverConfig(forSIMInfo simInfo: SIMInfo?,
                        prompt: Bool = false,
                        completion: @escaping DiscoveryServiceCompletion) {

        openIdConfig(forSIMInfo: simInfo, prompt: prompt) { result in
            guard !Thread.isMainThread else {
                completion(result)
                return
            }

            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}

private extension DiscoveryService {
    func openIdConfig(forSIMInfo simInfo: SIMInfo?,
                      prompt: Bool = false,
                      completion: @escaping DiscoveryServiceCompletion) {

        // if we have sim identifers, and aren't prompting we can attempt to use the cache:
        if let simInfo = simInfo, !prompt {
            let cachedConfig = recoverFromCache(simInfo: simInfo)
            guard cachedConfig == nil else {
                Log.log(.info, "Using Cached Config.")
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
        performDiscovery(for: simInfo, prompt: prompt, completion: completion)
    }

    func recoverFromCache(simInfo: SIMInfo) -> OpenIdConfig? {
        return configCacheService.config(forSIMInfo: simInfo)
    }

    func performDiscovery(for simInfo: SIMInfo?,
                          prompt: Bool = false,
                          completion: @escaping DiscoveryServiceCompletion) {

        let discoveryURL = discoveryEndpoint(forSIMInfo: simInfo, prompt: prompt)
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
                case .config(let carrierConfig):

                    self?.configCacheService.cacheConfig(
                        carrierConfig.openIdConfig,
                        forSIMInfo: carrierConfig.simInfo
                    )

                    completion(.knownMobileNetwork(carrierConfig))

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
}

private extension DiscoveryService {
    enum Params: String {
        case clientId = "client_id"
        case mccmnc
        case prompt
    }

    func discoveryEndpoint(forSIMInfo simInfo: SIMInfo?, prompt: Bool = false) -> URL {

        var params: [String: String] = [
            Params.clientId.rawValue: sdkConfig.clientId,
        ]

        if prompt {
            params[Params.prompt.rawValue] = String(prompt)
        }

        if let simInfo = simInfo {
            params[Params.mccmnc.rawValue] = simInfo.networkString
        }

        return hostConfig.resource(
            forPath: discoveryPath,
            queryItems: params
        )
    }
}

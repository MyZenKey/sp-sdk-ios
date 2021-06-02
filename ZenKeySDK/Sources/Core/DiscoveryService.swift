//
//  SharedAPI.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/21/19.
//  Copyright © 2019-2020 ZenKey, LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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

    /// Fetch the cached config that maps to sim.
    /// - Parameters:
    ///   - sim: The sim info to pass to the discovery service
    /// - Returns: Cached instance that conforms to ScopeZen.
    func cachedScopeZen(at sim: SIMProtocol) -> ScopeZen?

    /// Register for updates to qualified sp scopes.
    /// - Parameters:
    ///   - sim: The sim info to pass to the discovery service
    func registerScopeSubscriber(sim: SIMInfo?, _ publish: @escaping ScopePublisher)
}

extension DiscoveryServiceProtocol {
    func cachedScopeZen(at sim: SIMProtocol) -> ScopeZen? {
        .none
    }

    func registerScopeSubscriber(sim: SIMInfo?, _ publish: @escaping ScopePublisher) {
        return
    }
}

class DiscoveryService: DiscoveryServiceProtocol {
    private let sdkConfig: SDKConfig
    private let hostConfig: ZenKeyNetworkConfig
    private let networkService: NetworkServiceProtocol
    private let configCacheService: ConfigCacheServiceProtocol

    private let discoveryPath = "/.well-known/openid_configuration"
    private let discoveryEndpointFormat = "%@?&mccmnc=%@%@"
    private var observer: CacheObserver?

    init(sdkConfig: SDKConfig,
         hostConfig: ZenKeyNetworkConfig,
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

    func cachedScopeZen(at sim: SIMProtocol) -> ScopeZen? {
        guard let simInfo = sim as? SIMInfo else { return .none }
        return configCacheService.config(forSIMInfo: simInfo)
    }

    func registerScopeSubscriber(sim: SIMInfo?, _ publish: @escaping ScopePublisher) {
        guard let simInfo = sim else { return }
        observer = configCacheService.addCacheObserver() { [weak self] _ in
            guard let scopezen = self?.cachedScopeZen(at: simInfo) else { return }
            publish(scopezen.serviceProviderSupportedScopes)
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

            Log.log(.info, "Discovery outcome: \(result)")
            switch result {
            case .success(let configResult):
                // Because the endpoint can return either a config _or_ an error, we need to parse the
                // "inner" result and flatten the success or error.
                switch configResult {
                case .config(let carrierConfig):

                    // NTH: "pseudo sim" support, where we propagate returned simInfo to provide
                    // hints locally.
                    self?.configCacheService.cacheConfig(
                        carrierConfig.openIdConfig,
                        forSIMInfo: simInfo ?? carrierConfig.simInfo
                    )

                    completion(.knownMobileNetwork(carrierConfig))

                case .redirect(let redirect):
                    completion(.unknownMobileNetwork(redirect))

                case .error(let issuerError):
                    completion(.error(.issuerError(issuerError)))
                }

            case .failure(let error):
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
        case version = "sdk_version"
    }

    func discoveryEndpoint(forSIMInfo simInfo: SIMInfo?, prompt: Bool = false) -> URL {

        var params: [String: String] = [
            Params.clientId.rawValue: sdkConfig.clientId,
            Params.version.rawValue: VERSION,
        ]

        if prompt {
            params[Params.prompt.rawValue] = String(prompt)
        }

        if let simInfo = simInfo {
            params[Params.mccmnc.rawValue] = simInfo.mccmnc
        }

        return hostConfig.resource(
            forPath: discoveryPath,
            queryItems: params
        )
    }
}

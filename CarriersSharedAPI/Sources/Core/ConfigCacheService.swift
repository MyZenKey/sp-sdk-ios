//
//  ConfigCacheService.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 3/18/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

/// a service for storing configurations discovered through the discovery service
protocol ConfigCacheServiceProtocol {
    /// The duration the cached configs should be treated as relevant. Records with timestamps
    /// older than the TTL will be treated as stale.
    var cacheTTL: TimeInterval { get set }
    /// Sets a config in the cache for the provided SIM Identifers. The record in the cache receives
    /// the current time as a timestamp
    func cacheConfig(_ config: OpenIdConfig, forSIMInfo simInfo: SIMInfo)
    /// Retrieves a record for the provided identifier or nil from the cache. If a record is stale
    /// nil will be returned.
    func config(forSIMInfo simInfo: SIMInfo) -> OpenIdConfig?
}

/// Note: this class is not thread safe and assumes single threaded access
class ConfigCacheService: ConfigCacheServiceProtocol {

    var cacheTTL: TimeInterval = ConfigCacheService.defaultTTL

    private var cacheTimeStamps: [String: Date] = [:]

    private var cache: [String: OpenIdConfig] = [:]

    private let networkIdentifierCache: NetworkIdentifierCache

    init(networkIdentifierCache: NetworkIdentifierCache) {
        self.networkIdentifierCache = networkIdentifierCache
    }

    func cacheConfig(_ config: OpenIdConfig, forSIMInfo simInfo: SIMInfo) {
        let identifier = identifer(forSIMInfo: simInfo)
        cacheTimeStamps[identifier] = Date()
        cache[identifier] = config
    }

    func config(forSIMInfo simInfo: SIMInfo) -> OpenIdConfig? {

        let identifier = identifer(forSIMInfo: simInfo)
        let cachedTimeStamp = cacheTimeStamps[identifier] ?? Date.distantPast
        let cachedValue = cache[identifier]
        let cachedRecordIsValid = (abs(cachedTimeStamp.timeIntervalSinceNow) < cacheTTL)

        // record must be valid or we must permit stale records
        guard cachedRecordIsValid else {
            return nil
        }

        return cachedValue
    }

    private func identifer(forSIMInfo simInfo: SIMInfo) -> String {
        return "\(simInfo.mcc)\(simInfo.mnc)"
    }
}

private extension ConfigCacheService {

    /// default TTL is 15 mins
    static let defaultTTL: TimeInterval = ( 15 * 60 )

}

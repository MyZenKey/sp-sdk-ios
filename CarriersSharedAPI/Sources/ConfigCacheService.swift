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
    /// older than the TTL will be treated as stale. They may still be retrieved by passing
    /// `allowStaleRecords` to `config(forIdentifier:allowStaleRecords)`
    var cacheTTL: TimeInterval { get set }
    /// Sets a config in the cache for the provided SIM Identifers. The record in the cache receives
    /// the current time as a timestamp
    func cacheConfig(_ config: OpenIdConfig, forSIMInfo simInfo: SIMInfo)
    /// Retrieves a record for the provided identifier or nil from the cache. If `allowStaleRecords`
    /// is passed the cache will ignore the `cacheTTL` value and return the most recent record it has.
    func config(forSIMInfo simInfo: SIMInfo, allowStaleRecords: Bool) -> OpenIdConfig?
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
    
    func config(forSIMInfo simInfo: SIMInfo,
                allowStaleRecords: Bool) -> OpenIdConfig? {
        
        let identifier = identifer(forSIMInfo: simInfo)
        let cachedTimeStamp = cacheTimeStamps[identifier] ?? Date.distantPast
        let cachedValue = cache[identifier]
        let cachedRecordIsValid = (abs(cachedTimeStamp.timeIntervalSinceNow) < cacheTTL)

        // record must be valid or we must permit stale records
        guard cachedRecordIsValid || allowStaleRecords else {
            return nil
        }
        
        // if there is no record, fallback on bundled record
        guard let record = cachedValue else {
            return fallbackToBundle(forSIMInfo: simInfo)
        }
        
        return record
    }
    
    private func fallbackToBundle(forSIMInfo simInfo: SIMInfo) -> OpenIdConfig? {
        // fall back on bundled data if this is a known mobile network operator:
        let carrier = self.networkIdentifierCache.carrier(
            forMcc: simInfo.mcc,
            mnc: simInfo.mnc
        )
        return ConfigCacheService.bundledDiscoveryData[carrier.shortName]
    }
    
    private func identifer(forSIMInfo simInfo: SIMInfo) -> String {
        return "\(simInfo.mcc)\(simInfo.mnc)"
    }
}

private extension ConfigCacheService {
    
    /// default TTL is 15 mins
    static let defaultTTL: TimeInterval = ( 15 * 60 )
    
    static let bundledDiscoveryData = [
        "tmo": OpenIdConfig(
            tokenEndpoint: URL(string: "https://brass.account.t-mobile.com/tms/v3/usertoken")!,
            authorizationEndpoint: URL(string: "https://account.t-mobile.com/oauth2/v1/auth")!,
            issuer: URL(string: "https://ppd.account.t-mobile.com")!
        ),
        "vzw": OpenIdConfig(
            tokenEndpoint: URL(string: "https://auth.svcs.verizon.com:22790/vzconnect/token")!,
            authorizationEndpoint: URL(string: "https://auth.svcs.verizon.com:22790/vzconnect/authorize")!,
            issuer: URL(string: "https://auth.svcs.verizon.com")!
        ),
        "att": OpenIdConfig(
            tokenEndpoint: URL(string: "https://oidc.test.xlogin.att.com/mga/sps/oauth/oauth20/token")!,
            authorizationEndpoint: URL(string: "xci://authorize")!,
//            authorizationEndpoint: URL(string: "https://oidc.test.xlogin.att.com/mga/sps/oauth/oauth20/authorize")!,
            issuer: URL(string: "https://oidc.test.xlogin.att.com")!
        ),
    ]
}

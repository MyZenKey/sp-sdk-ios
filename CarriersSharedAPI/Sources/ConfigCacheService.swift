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
    /// Sets a config in the cache for the provided SIM Identifers. The record in the cache recieves
    /// the current time as a timestamp
    func cacheConfig(_ config: OpenIdConfig, forSIMInfo simInfo: SIMInfo)
    /// Retrieves a record for the provided identifier or nil fromt the cache. If `allowStaleRecords`
    /// is passed the cache will ignore the `cacheTTL` value and return the most recent record it has.
    func config(forSIMInfo simInfo: SIMInfo, allowStaleRecords: Bool) -> OpenIdConfig?
}

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
        // fall back on bundled data if known mno:
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

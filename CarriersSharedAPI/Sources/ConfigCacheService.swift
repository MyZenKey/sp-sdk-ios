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
    /// Sets a config in the cache for the provided identifier. The record in the cache recieves
    /// the current time as a timestamp
    func cacheConfig(_ config: OpenIdConfig, forIdentifier identifier: String)
    /// Retrieves a record for the provided identifier or nil fromt the cache. If `allowStaleRecords`
    /// is passed the cache will ignore the `cacheTTL` value and return the most recent record it has.
    func config(forIdentifier identifier: String, allowStaleRecords: Bool) -> OpenIdConfig?
}

class ConfigCacheService: ConfigCacheServiceProtocol {

    var cacheTTL: TimeInterval = ConfigCacheService.defaultTTL

    private var cacheTimeStamps: [String: Date] = [:]

    private var cache: [String: OpenIdConfig] = ConfigCacheService.bundledDiscoveryData
    
    func cacheConfig(_ config: OpenIdConfig, forIdentifier identifier: String) {
        cacheTimeStamps[identifier] = Date()
        cache[identifier] = config
    }
    
    func config(forIdentifier identifier: String,
                allowStaleRecords: Bool) -> OpenIdConfig? {
        
        let cachedTimeStamp = cacheTimeStamps[identifier] ?? Date.distantPast
        guard
            let cachedValue = cache[identifier],
            (allowStaleRecords || (abs(cachedTimeStamp.timeIntervalSinceNow) < cacheTTL)) else {
                return nil
        }

        return cachedValue
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

//
//  ConfigCacheService.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 3/18/19.
//  Copyright © 2019 XCI JV, LLC.
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
    /// Adds an action to the list of cache observers. The action is triggered every time the cache
    /// changes.
    ///
    /// - Parameter action: the action to perform on each change
    /// - Returns: the observer value. Hold a strong reference to this value – the chahe will only
    /// hold a weak reference.
    func addCacheObserver(_ action: @escaping CacheObserver.Action) -> CacheObserver
}

final class CacheObserver {
    typealias Action = (SIMInfo) -> Void

    private(set) var isCancelled = false

    private let action: Action

    init(_ action: @escaping Action) {
        self.action = action
    }

    func onChange(forSIMInfo simInfo: SIMInfo) {
        guard !isCancelled else {
            return
        }
        action(simInfo)
    }

    func cancel() {
        isCancelled = true
    }
}

/// Note: this class is not thread safe and assumes single threaded access
class ConfigCacheService: ConfigCacheServiceProtocol {

    var cacheTTL: TimeInterval = ConfigCacheService.defaultTTL

    private var cacheTimeStamps: [String: Date] = [:]

    private var cache: [String: OpenIdConfig] = [:]
    private var cacheObservers: NSHashTable = NSHashTable<CacheObserver>(options: .weakMemory)

    func cacheConfig(_ config: OpenIdConfig, forSIMInfo simInfo: SIMInfo) {
        let identifier = identifer(forSIMInfo: simInfo)
        cacheTimeStamps[identifier] = Date()
        cache[identifier] = config
        cacheObservers.allObjects
            .forEach({ $0.onChange(forSIMInfo: simInfo) })
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

    func addCacheObserver(_ action: @escaping CacheObserver.Action) -> CacheObserver {
        let observer = CacheObserver(action)
        cacheObservers.add(observer)
        return observer
    }

    private func identifer(forSIMInfo simInfo: SIMInfo) -> String {
        return "\(simInfo.mcc)\(simInfo.mnc)"
    }
}

private extension ConfigCacheService {

    /// default TTL is 15 mins
    static let defaultTTL: TimeInterval = ( 15 * 60 )

}

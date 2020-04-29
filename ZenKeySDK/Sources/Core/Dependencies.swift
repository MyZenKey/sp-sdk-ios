//
//  Dependencies.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/28/19.
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

import Foundation
#if os(iOS)
import CoreTelephony
#endif

public enum ZenKeyOptionKeys: String {
    case qaHost
    case logLevel
    case mockedCarrier
}

public typealias ZenKeyOptions = [ZenKeyOptionKeys: Any]

class Dependencies {

    let sdkConfig: SDKConfig
    let options: ZenKeyOptions

    private var dependencies: [String: Dependency] = [:]

    init(sdkConfig: SDKConfig, options: ZenKeyOptions = [:]) {
        self.sdkConfig = sdkConfig
        self.options = options
        self.buildDependencies()
    }

    // swiftlint:disable:next function_body_length
    private func buildDependencies() {
        Log.configureLogger(level: options.logLevel)
        let host: ZenKeyNetworkConfig.Host = options.host
        let hostConfig = ZenKeyNetworkConfig(host: host)

        // this is a little silly, just to make sdkconfig available to be resolved...
        // maybe rehthink this
        register(type: SDKConfig.self, scope: .singleton) { container in
            return container.sdkConfig
        }

        // config cache service will be a shared resource:
        register(type: ConfigCacheServiceProtocol.self, scope: .singleton) { _ in
            return ConfigCacheService()
        }

        register(type: NetworkServiceProtocol.self) { _ in
            return NetworkService()
        }

        register(type: DiscoveryServiceProtocol.self) { container in
            return DiscoveryService(
                sdkConfig: container.sdkConfig,
                hostConfig: hostConfig,
                networkService: NetworkService(),
                configCacheService: container.resolve()
            )
        }

        #if os(iOS)
            register(type: MobileNetworkInfoProvider.self) { container in
                return container.resolveNetworkInfoProvider()
            }

            register(type: CarrierInfoServiceProtocol.self) { container in
                return CarrierInfoService(
                    mobileNetworkInfoProvider: container.resolve()
                )
            }

            register(type: MobileNetworkSelectionServiceProtocol.self) { container in
                return MobileNetworkSelectionService(
                    sdkConfig: container.resolve(),
                    mobileNetworkSelectionUI: WebBrowserUI()
                )
            }

            register(type: OpenIdServiceProtocol.self) { _ in
                return OpenIdService(
                    urlResolver: OpenIdURLResolverIOS()
                )
            }

            register(type: AuthorizationServiceProtocolInternal.self) { container in
                return AuthorizationServiceIOS(
                    sdkConfig: container.resolve(),
                    discoveryService: container.resolve(),
                    openIdService: container.resolve(),
                    carrierInfoService: container.resolve(),
                    mobileNetworkSelectionService: container.resolve()
                )
            }

            register(type: BrandingProvider.self) { container in
                return CurrentSIMBrandingProvider(
                    configCacheService: container.resolve(),
                    carrierInfoService: container.resolve()
                )
            }
        #else
            fatalError("currently only supports iOS")
        #endif

        Log.log(.info, "Configured Dependency Graph: \(dependencies)")
    }
}

protocol Dependency {
    var value: Any { get }
}

private extension Dependencies {
    class Singleton<T>: Dependency {
        private let factory: () -> T
        lazy private(set) var value: Any = {
            return self.factory()
        }()

        init(_ factory: @autoclosure @escaping () -> T) {
            self.factory = factory
        }
    }

    class Factory<T>: Dependency {
        var value: Any {
            return factory()
        }
        private let factory: () -> T
        init(_ factory: @autoclosure @escaping () -> T) {
            self.factory = factory
        }
    }

    enum Scope {
        case factory
        case singleton
    }

    func register<T>(type: T.Type, scope: Scope = .factory, _ factory: @escaping (Dependencies) -> T) {
        switch scope {
        case .factory:
            dependencies["\(type)"] = Factory<T>(factory(self))

        case .singleton:
            dependencies["\(type)"] = Singleton<T>(factory(self))
        }
    }
}

extension Dependencies {
    /// Pulls the registered instance of the inferred type out of the dependency container.
    func resolve<T>() -> T {
        return resolveFor(name: "\(T.self)")
    }
    /// Pulls the registered instance of the inferred type out of the dependency container.
    func resolve<T: WrappedDependency>() -> T {
        return resolveFor(name: "\(T.innerType)")
    }

    private func resolveFor<T>(name: String) -> T {
        guard let dependency = dependencies["\(name)"], let value = dependency.value as? T else {
            fatalError("attempting to resolve a dependency of type \(name) that doesn't exist")
        }

        return value
    }
}

protocol WrappedDependency {
    static var innerType: Any.Type { get }
}
extension Optional: WrappedDependency {
    static var innerType: Any.Type { Wrapped.self }
}

private extension Dependencies {
    func resolveNetworkInfoProvider() -> MobileNetworkInfoProvider {
        #if DEBUG
        if let mockedCarrier = options[.mockedCarrier] as? Carrier {
            return MockSIMNetworkInfoProvider(carrier: mockedCarrier)
        } else {
            return CTTelephonyNetworkInfo()
        }
        #else
        return CTTelephonyNetworkInfo()
        #endif
    }
}

private extension Dictionary where Key == ZenKeyOptionKeys, Value: Any {
    var host: ZenKeyNetworkConfig.Host {
        let qaFlag = self[.qaHost, or: false]
        return qaFlag ? .qa : .production
    }

    var logLevel: Log.Level {
        return self[.logLevel, or: .off]
    }
}

extension Dependencies.Singleton: CustomStringConvertible {
    var description: String {
        return "Singleton<\(T.self)>"
    }
}

extension Dependencies.Factory: CustomStringConvertible {
    var description: String {
        return "Factory<\(T.self)>"
    }
}

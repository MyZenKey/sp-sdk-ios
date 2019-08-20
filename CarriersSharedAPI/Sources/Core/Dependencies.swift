//
//  Dependencies.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/28/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
#if os(iOS)
import CoreTelephony
#endif

public enum ProjectVerifyOptionKeys: String {
    case qaHost
    case logLevel
    case mockedCarrier
}

public typealias ProjectVerifyOptions = [ProjectVerifyOptionKeys: Any]

class Dependencies {

    let sdkConfig: SDKConfig
    let options: ProjectVerifyOptions

    private(set) var all: [Any] = []

    private var dependencies: [String: Dependency] = [:]

    init(sdkConfig: SDKConfig, options: ProjectVerifyOptions = [:]) {
        self.sdkConfig = sdkConfig
        self.options = options
        self.buildDependencies()
    }

    private func buildDependencies() {

        Log.configureLogger(level: options.logLevel)
        let host: ProjectVerifyNetworkConfig.Host = options.host

        let hostConfig = ProjectVerifyNetworkConfig(host: host)

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

            register(type: MobileNetworkSelectionServiceProtocol.self) { _ in
                return MobileNetworkSelectionService(
                    sdkConfig: self.sdkConfig,
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
        var value: Any {
            guard let value = _value else {
                let value = factory()
                _value = value
                return value
            }
            return value
        }
        private var _value: T?
        private let factory: () -> T
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
    func resolve<T>() -> T {
        guard let dependency = dependencies["\(T.self)"] else {
            fatalError("attemtping to resolve a dependency of type \(T.self) that doesn't exist")
        }

        // FIXME: support optionals or remove type inferrence api
        // currently this type infrence doesn't support inferring the wrapped inner out of an
        // optional type – it will fail with a fatal error. use a non-optional typed var as a work
        // around in the mean time.
        guard let typedValue = dependency.value as? T else {
            fatalError("attemtping to resolve a dependency of type \(T.self) that doesn't exist")
        }

        return typedValue
    }
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

private extension Dictionary where Key == ProjectVerifyOptionKeys, Value: Any {
    var host: ProjectVerifyNetworkConfig.Host {
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

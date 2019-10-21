//
//  DependenciesTests.swift
//  ZenKeySDK-Unit-Tests
//
//  Created by Adam Tierney on 8/21/19.
//

import XCTest
@testable import ZenKeySDK

class DependenciesTests: XCTestCase {

    func testBuildDependencies() {
        let passedConfig = SDKConfig(clientId: "mock", redirectScheme: "mock")
        let dependencies = Dependencies(sdkConfig: passedConfig)

        let config: SDKConfig = dependencies.resolve()
        XCTAssertEqual(passedConfig, config)

        assertResolutionViaSingleton(type: ConfigCacheServiceProtocol.self, fromContainer: dependencies)

        assertResolutionViaFactory(type: NetworkServiceProtocol.self, fromContainer: dependencies)

        assertResolutionViaFactory(type: DiscoveryServiceProtocol.self, fromContainer: dependencies)

        assertResolutionViaFactory(type: MobileNetworkInfoProvider.self, fromContainer: dependencies)

        assertResolutionViaFactory(type: CarrierInfoServiceProtocol.self, fromContainer: dependencies)

        assertResolutionViaFactory(type: MobileNetworkSelectionServiceProtocol.self, fromContainer: dependencies)

        assertResolutionViaFactory(type: OpenIdServiceProtocol.self, fromContainer: dependencies)

        assertResolutionViaFactory(type: AuthorizationServiceProtocolInternal.self, fromContainer: dependencies)

        assertResolutionViaFactory(type: BrandingProvider.self, fromContainer: dependencies)
    }
}

func assertResolutionViaFactory<T>(type: T.Type, fromContainer container: Dependencies) {
    let valueA: T = container.resolve()
    let valueB: T = container.resolve()
    // NOTE: value types are boxed into objects when downcasted. They will therefore always represent
    // a different type, which is consistent with the way they will be enforced.
    XCTAssertFalse(valueA as AnyObject === valueB as AnyObject)
}

func assertResolutionViaSingleton<T>(type: T.Type, fromContainer container: Dependencies) {
    let valueA: T = container.resolve()
    let valueB: T = container.resolve()
    // NOTE: value types are boxed into objects when downcasted. They will therefore always represent
    // a different type, which is consistent with the way they will be enforced.
    XCTAssertTrue(valueA as AnyObject === valueB as AnyObject)
}

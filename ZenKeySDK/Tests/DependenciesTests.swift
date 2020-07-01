//
//  DependenciesTests.swift
//  ZenKeySDK-Unit-Tests
//
//  Created by Adam Tierney on 8/21/19.
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

        assertOptionalResolution(type: DiscoveryServiceProtocol.self, fromContainer: dependencies)
    }
}

func assertOptionalResolution<T>(type: T.Type, fromContainer container: Dependencies) {
    let value: T? = container.resolve()
    XCTAssertNotNil(value)
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

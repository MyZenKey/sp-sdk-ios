//
//  ScopeTests.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/26/19.
//  Copyright © 2019 ZenKey, LLC. All rights reserved.
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

// swiftlint:disable empty_enum_arguments

class ScopeTests: XCTestCase {
    var dupeScopes: [ScopeProtocol] = {
        let scopes: [Scope] = [.name, .openid, .phone, .phone, .name, .name, .openid]
        return scopes
    }()

    func testDedupedSortedOpenIdScopeString() {
        XCTAssertEqual(dupeScopes.toOpenIdScopes, "name openid phone")
    }

    func testPrependRequiredOpenIdScope() {
        let formattedString = OpenIdScopes(requestedScopes: dupeScopes).networkFormattedString
        XCTAssertEqual(formattedString, "name openid phone")
    }

    func mockOpenIdConfig(json: String) -> OpenIdConfig? {
        let mockRequest = URLRequest(url: URL.mocked)
        let jsonDecoder = JSONDecoder()
        let mockPayload = json.data(using: .utf8)
        let result: Result<OpenIdConfig, NetworkServiceError> = NetworkService.JSONResponseParser.parseDecodable(
            with: jsonDecoder,
            fromData: mockPayload,
            request: mockRequest,
            error: .none
        )
        switch result {
        case .success(let config):
            return config
        case .failure( _ ):
            return .none
        }
    }

    func testUniversalScopesNotEmpty() {
        XCTAssertFalse(Scope.universalScopes.isEmpty)
    }

    func testUniversalScopesNotInPremium() {
        let subSet = Scope.universalScopes.filter { item in
            Scope.premiumScopes.contains { premiumItem in
            item.scopeString == premiumItem.scopeString } }
        XCTAssertTrue(subSet.isEmpty)
    }

    func testStringToScope() {
        let input = ["name", "openid", "phone", "proofing"]
        XCTAssertEqual(Scope.toScopes(rawValues: input).toOpenIdScopes, input.joined(separator: " "))
    }

    func testStringToScopeNoDupsSorted() {
        let input = ["openid", "name", "phone", "phone", "name", "name", "openid"]
        XCTAssertEqual(Scope.toScopes(rawValues: input).toOpenIdScopes, "name openid phone")
    }

    func testStringToScopeNonExist() {
        let realScopeName = "proofing"
        let input = ["\(realScopeName)", "elmer", "fudd", "yosemite", "sam"]
        XCTAssertEqual(Scope.toScopes(rawValues: input).toOpenIdScopes, "\(realScopeName)")
    }

    func testOpenIdConfigWithProofingScope() {
        guard let openIdConfigWithProofing = mockOpenIdConfig(json: mockOpenIDConfigWithProofing) else {
            XCTFail("Invalid JSON")
            return
        }
        XCTAssertTrue(openIdConfigWithProofing.serviceProviderSupportedScopes.map { $0.scopeString }.contains(Scope.proofing.rawValue))
    }

    func testOpenIdConfigWithOutProofingScope() {
        guard let openIdConfigNoProofing = mockOpenIdConfig(json: mockOpenIDConfigNoProofing) else {
            XCTFail("Invalid JSON")
            return
        }
        XCTAssertFalse(openIdConfigNoProofing.serviceProviderSupportedScopes.map { $0.scopeString }.contains(Scope.proofing.rawValue))
    }

    // Tests that my subscriber is notified when the openIdConfig gets cached in ConfigCacheService
    func testPublisherToSubscriber() {
        let timeout = 5.0
        let expect = XCTestExpectation(description: "wait")
        let sim = MockSIMInfo()
        var mockBundle = MockInjectionBundle()
        mockBundle.info = mockOpenIdConfig(json: mockOpenIDConfigWithProofing)
        mockBundle.sim = sim
        mockBundle.closure = {
            // SDK bootstrap complete, stand up subscriber for publisher
            _ = MockSubscriber(expect: expect, sim: sim)
        }
        ZenKeyAppDelegate.shared.inject(bundle: mockBundle)
        ZenKeyAppDelegate.shared.application(UIApplication.shared,
                                             didFinishLaunchingWithOptions: .none)
        wait(for: [expect], timeout: timeout)
    }
}

struct MockSubscriber {
    var expect: XCTestExpectation
    var sim: SIMProtocol
    init(expect: XCTestExpectation, sim: SIMProtocol) {
        self.expect = expect
        self.sim = sim

        // register to be notified when openIdConfig gets cached in ConfigCacheService
        ZenKeyAppDelegate.shared.register(sim: sim) { _ in
            expect.fulfill()
        }
    }
}

struct MockInjectionBundle: ZenKeyBundleProtocol {
    var clientId: String? = "ccid-pxap3evoqfczqmjk"
    var urlSchemes: [String] = ["ccid-pxap3evoqfczqmjk"]
    var customURLScheme: String? = "ccid-pxap3evoqfczqmjk"
    var customURLHost: String? = "com.xci.provider.sdk"
    var customURLPath: String? = ""
    var info: Any?
    var sim: SIMProtocol?
    var closure: BundleClosure?
}

struct MockSIMInfo: SIMProtocol {
    var mccmnc: String = "310260"
}

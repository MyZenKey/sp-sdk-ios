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

    func testPremiumScopesExclusive() {
        XCTAssertTrue(Scope.premiumScopes.filter { Scope.universalScopes.contains($0) }.isEmpty)
    }

    func testUniversalScopesExclusive() {
        XCTAssertTrue(Scope.universalScopes.filter { Scope.premiumScopes.contains($0) }.isEmpty)
    }

    func testUniversalScopesNotEmpty() {
        XCTAssertFalse(Scope.universalScopes.isEmpty)
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
}

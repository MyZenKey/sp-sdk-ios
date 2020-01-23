//
//  ScopeTests.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/26/19.
//  Copyright © 2019 ZenKey, LLC. All rights reserved.
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
}

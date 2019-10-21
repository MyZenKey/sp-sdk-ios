//
//  ScopeTests.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/26/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest
@testable import ZenKeySDK

class ScopeTests: XCTestCase {
    var dupeScopes: [ScopeProtocol] = {
        let scopes: [Scope] = [.match, .match, .score, .score, .match, .authorize]
        return scopes
    }()

    func testDedupedSortedOpenIdScopeString() {
        XCTAssertEqual(dupeScopes.toOpenIdScopes, "authorize match score")
    }

    func testPrependRequiredOpenIdScope() {
        let formattedString = OpenIdScopes(requestedScopes: dupeScopes).networkFormattedString
        XCTAssertEqual(formattedString, "authorize match score")
    }
}

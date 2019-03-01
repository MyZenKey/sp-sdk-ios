//
//  ScopeTests.swift
//  AppAuth
//
//  Created by Adam Tierney on 2/26/19.
//

import XCTest
@testable import CarriersSharedAPI

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
        XCTAssertEqual(formattedString, "openid authorize match score")
    }
}

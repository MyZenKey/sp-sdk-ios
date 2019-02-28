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

    func testDeDupedSortedNetworkString() {
        XCTAssertEqual(dupeScopes.networkFormattedScopes, "authorize match score")
    }
}

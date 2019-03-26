//
//  SDKConfigTests.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 3/7/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest
@testable import CarriersSharedAPI

class MockBundle: ProjectVerifyBundleProtocol {
    var clientId: String?
    var urlSchemes: [String] = []

    func clear() {
        clientId = nil
        urlSchemes = []
    }
}

class SDKConfigTests: XCTestCase {

    let mockBundle = MockBundle()

    override func setUp() {
        super.setUp()
        self.mockBundle.clear()
    }

    func testMissingClientIdError() {
        XCTAssertThrowsError(try SDKConfig.load(fromBundle: mockBundle)) { error in
            XCTAssertEqual(error as? BundleLoadingErrors, BundleLoadingErrors.specifyClientId)
        }
    }

    func testMissingURLSchemeError() {
        mockBundle.clientId = "foo"
        XCTAssertThrowsError(try SDKConfig.load(fromBundle: mockBundle)) { error in
            XCTAssertEqual(error as? BundleLoadingErrors, BundleLoadingErrors.specifyRedirectURLScheme)
        }
    }

    func testCorrectBundleURL() {
        mockBundle.clientId = "foo"
        mockBundle.urlSchemes = ["bar", "biz", "foo", "bah"]
        do {
            let config = try SDKConfig.load(fromBundle: mockBundle)
            XCTAssertEqual(config.redirectURL, URL(string: "foo://code")!)
        } catch {
            XCTFail("expected not to throw")
        }
    }
}

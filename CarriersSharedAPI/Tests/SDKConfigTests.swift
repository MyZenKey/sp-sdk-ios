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
    var customURLScheme: String?
    var customURLHost: String?

    func clear() {
        clientId = nil
        urlSchemes = []
        customURLScheme = nil
        customURLHost = nil
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

    func testRedirectSchemeIsClientIdByDefault() {
        let clientId = "foo"
        mockBundle.clientId = clientId
        mockBundle.urlSchemes = ["bar", "biz", clientId, "bah"]
        do {
            let config = try SDKConfig.load(fromBundle: mockBundle)
            XCTAssertEqual(config.redirectScheme, clientId)
        } catch {
            XCTFail("expected not to throw")
        }
    }

    func testRedirectSchemeIsCustomSchemeIfProvided() {
        let customScheme = "https"
        mockBundle.clientId = "foo"
        mockBundle.customURLScheme = customScheme
        mockBundle.urlSchemes = ["bar", "biz", customScheme, "bah"]
        do {
            let config = try SDKConfig.load(fromBundle: mockBundle)
            XCTAssertEqual(config.redirectScheme, customScheme)
        } catch {
            XCTFail("expected not to throw")
        }
    }

    func testHostIsCustomHostIfProvided() {
        let customHost = "customhost"
        mockBundle.clientId = "foo"
        mockBundle.customURLScheme = "https"
        mockBundle.customURLHost = customHost
        do {
            let config = try SDKConfig.load(fromBundle: mockBundle)
            XCTAssertEqual(config.redirectHost, customHost)
        } catch {
            XCTFail("expected not to throw")
        }
    }

    func testURLBuilderUsesRedirectScheme() {
        let customScheme = "https"
        mockBundle.clientId = "foo"
        mockBundle.customURLScheme = "https"
        mockBundle.customURLScheme = customScheme
        do {
            let config = try SDKConfig.load(fromBundle: mockBundle)
            let url = config.redirectURL(forRoute: .authorize)
            XCTAssertEqual(url.scheme, mockBundle.customURLScheme)
        } catch {
            XCTFail("expected not to throw")
        }
    }

    func testURLBuilderUsesRedirectHost() {
        let customHost = "customhost"
        mockBundle.clientId = "foo"
        mockBundle.customURLScheme = "https"
        mockBundle.customURLHost = customHost
        do {
            let config = try SDKConfig.load(fromBundle: mockBundle)
            let url = config.redirectURL(forRoute: .authorize)
            XCTAssertEqual(url.host, mockBundle.customURLHost)
        } catch {
            XCTFail("expected not to throw")
        }
    }

    func testCodeRedirectURLFormatsCorrectly() {
        let clientId = "foo"
        mockBundle.clientId = clientId
        mockBundle.urlSchemes = ["bar", "biz", clientId, "bah"]
        do {
            let config = try SDKConfig.load(fromBundle: mockBundle)
            XCTAssertEqual(config.redirectURL(forRoute: .authorize), URL(string: "foo://projectverify/authorize")!)
        } catch {
            XCTFail("expected not to throw")
        }
    }

    func testDiscoveryRedirectURLFormatsCorrectly() {
        let clientId = "foo"
        mockBundle.clientId = clientId
        mockBundle.urlSchemes = ["bar", "biz", clientId, "bah"]
        do {
            let config = try SDKConfig.load(fromBundle: mockBundle)
            XCTAssertEqual(config.redirectURL(forRoute: .discoveryUI), URL(string: "foo://projectverify/discoveryui")!)
        } catch {
            XCTFail("expected not to throw")
        }
    }
}

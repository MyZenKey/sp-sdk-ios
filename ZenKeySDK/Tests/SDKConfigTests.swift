//
//  SDKConfigTests.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 3/7/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest
@testable import ZenKeySDK

class MockBundle: ZenKeyBundleProtocol {
    var clientId: String?
    var urlSchemes: [String] = []
    var customURLScheme: String?
    var customURLHost: String?
    var customURLPath: String?

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

    func testRedirectURLUsesDefaultHost() {
        mockBundle.clientId = "foo"
        mockBundle.customURLScheme = "https"
        do {
            let config = try SDKConfig.load(fromBundle: mockBundle)
            XCTAssertEqual(config.redirectHost, SDKConfig.Default.host.rawValue)
        } catch {
            XCTFail("expected not to throw")
        }
    }

    func testRedirectURLUsesDefaultPath() {
        mockBundle.clientId = "foo"
        mockBundle.customURLScheme = "https"
        do {
            let config = try SDKConfig.load(fromBundle: mockBundle)
            XCTAssertEqual(config.redirectPath, SDKConfig.Default.path.rawValue)
        } catch {
            XCTFail("expected not to throw")
        }
    }

    func testRedirectSchemeIsCustomIfProvided() {
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

    func testHostIsCustomIfProvided() {
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

    func testPathIsCustomIfProvided() {
        let customPath = "/my/custom/path"
        mockBundle.clientId = "foo"
        mockBundle.customURLScheme = "https"
        mockBundle.customURLPath = customPath

        do {
            let config = try SDKConfig.load(fromBundle: mockBundle)
            XCTAssertEqual(config.redirectPath, customPath)
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
            let url = config.redirectURL
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
            let url = config.redirectURL
            XCTAssertEqual(url.host, mockBundle.customURLHost)
        } catch {
            XCTFail("expected not to throw")
        }
    }

    func testURLBuilderUsesRedirectPath() {
        let customPath = "/my/custom/path"
        mockBundle.clientId = "foo"
        mockBundle.customURLScheme = "https"
        mockBundle.customURLPath = customPath
        do {
            let config = try SDKConfig.load(fromBundle: mockBundle)
            let url = config.redirectURL
            XCTAssertEqual(url.path, mockBundle.customURLPath)
        } catch {
            XCTFail("expected not to throw")
        }
    }
}

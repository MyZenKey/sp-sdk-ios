//
//  MobileNetworkSelectionServiceTests.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 4/19/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest
import Foundation
@testable import CarriersSharedAPI

class MockMobileNetworkSelectionUI: MobileNetworkSelectionUIProtocol {

    var lastViewController: UIViewController?
    var lastURL: URL?
    var lastOnUIDidCancel: (() -> Void)?

    func showMobileNetworkSelectionUI(
        fromController viewController: UIViewController,
        usingURL url: URL,
        onUIDidCancel: @escaping () -> Void) {

        lastViewController = viewController
        lastURL = url
        lastOnUIDidCancel = onUIDidCancel
    }

    func close(completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            completion()
        }
    }
}

class MockStateGenerator {

    static var returnValue: String? = "test-state"

    static func clear() {
        returnValue = "test-state"
    }

    static func generate() -> String? {
        return MockStateGenerator.returnValue
    }
}

class MobileNetworkSelectionServiceTests: XCTestCase {

    static let resource = URL(string: "https://app.xcijv.com/ui/discovery-ui")!

    static let validRequestURL = URL(
        // swiftlint:disable:next line_length
        string: "https://app.xcijv.com/ui/discovery-ui?client_id=mockClientId&redirect_uri=mockClientId://com.xci.provider.sdk/projectverify/discoveryui&state=test-state"
    )!

    static let mockClientId = "mockClientId"
    let mockSDKConfig = SDKConfig(
        clientId: MobileNetworkSelectionServiceTests.mockClientId,
        redirectScheme: MobileNetworkSelectionServiceTests.mockClientId
    )

    let mockMobileNetworkSelectionUI = MockMobileNetworkSelectionUI()

    lazy var mobileNetworkSelectionService = MobileNetworkSelectionService(
        sdkConfig: mockSDKConfig,
        mobileNetworkSelectionUI: mockMobileNetworkSelectionUI,
        stateGenerator: MockStateGenerator.generate
    )

    override func setUp() {
        super.setUp()
        MockStateGenerator.clear()
    }

    func testCallsMobileNetworkSelectionUIWithViewController() {
        let controller = MockWindowViewController()
        mobileNetworkSelectionService.requestUserNetworkSelection(
            fromResource: MobileNetworkSelectionServiceTests.resource,
            fromCurrentViewController: controller) { _ in }
        XCTAssertTrue(mockMobileNetworkSelectionUI.lastViewController === controller)
    }

    func testCorrectSafariControllerURL() {
        let controller = MockWindowViewController()
        mobileNetworkSelectionService.requestUserNetworkSelection(
            fromResource: MobileNetworkSelectionServiceTests.resource,
            fromCurrentViewController: controller) { _ in }
        let expectedURL = MobileNetworkSelectionServiceTests.validRequestURL
        XCTAssertEqual(mockMobileNetworkSelectionUI.lastURL, expectedURL)
    }

    func testDuplicateRequestsCancelsPrevious() {
        mobileNetworkSelectionService.requestUserNetworkSelection(
            fromResource: MobileNetworkSelectionServiceTests.resource,
            fromCurrentViewController: MockWindowViewController()) { result in
                guard case .cancelled = result else {
                    XCTFail("expected to cancel if a second request is made")
                    return
                }
        }
        mobileNetworkSelectionService.requestUserNetworkSelection(
            fromResource: MobileNetworkSelectionServiceTests.resource,
            fromCurrentViewController: UIViewController()) { _ in }
    }

    func testResolveURLReturnsFalseWhenNoRequestInflight() {
        let url = URL.mocked
        XCTAssertFalse(mobileNetworkSelectionService.resolve(url: url))
    }

    func testConcludesWithErrorForUnableToGenerateState() {
        MockStateGenerator.returnValue = nil
        let expectation = XCTestExpectation(description: "wait")
        mobileNetworkSelectionService.requestUserNetworkSelection(
            fromResource: MobileNetworkSelectionServiceTests.resource,
            fromCurrentViewController: MockWindowViewController()) { result in
                defer { expectation.fulfill() }
                guard
                    case .error(let error) = result,
                    case .stateError(let stateError) = error,
                    case .generationFailed = stateError else {
                        XCTFail("expected state generation error")
                        return
                }
        }

        wait(for: [expectation], timeout: timeout)
    }

    func testConcludesWithErrorForMismatchState() {
        let expectation = XCTestExpectation(description: "wait")
        mobileNetworkSelectionService.requestUserNetworkSelection(
            fromResource: MobileNetworkSelectionServiceTests.resource,
            fromCurrentViewController: MockWindowViewController()) { result in
                defer { expectation.fulfill() }
                guard
                    case .error(let error) = result,
                    case .urlResponseError(let urlError) = error,
                    case .stateMismatch = urlError else {
                    XCTFail("expected state mismatch error")
                    return
                }
        }

        let url = URL.mocked
        let didResolve = mobileNetworkSelectionService.resolve(url: url)
        XCTAssertTrue(didResolve)
        wait(for: [expectation], timeout: timeout)
    }

    func testConcludesWithErrorForInvlaidMCCMNC() {
        let expectation = XCTestExpectation(description: "wait")
        mobileNetworkSelectionService.requestUserNetworkSelection(
            fromResource: MobileNetworkSelectionServiceTests.resource,
            fromCurrentViewController: MockWindowViewController()) { result in
                defer { expectation.fulfill() }
                guard
                    case .error(let error) = result,
                    case MobileNetworkSelectionError.invalidMCCMNC = error  else {
                        XCTFail("expected invalid mccmnc error")
                        return
                }
        }

        let url = URL(string: "foo://test?mccmnc=abcdefghijklmnopqrstuvwxyz&state=test-state")!
        let didResolve = mobileNetworkSelectionService.resolve(url: url)
        XCTAssertTrue(didResolve)
        wait(for: [expectation], timeout: timeout)

    }

    func testConcludesWithSuccess() {
        let mcc = "123"
        let mnc = "456"
        let hintToken = "abc123"
        let expectation = XCTestExpectation(description: "wait")
        mobileNetworkSelectionService.requestUserNetworkSelection(
            fromResource: MobileNetworkSelectionServiceTests.resource,
            fromCurrentViewController: MockWindowViewController()) { result in
                defer { expectation.fulfill() }
                guard
                    case .networkInfo(let response) = result else {
                        XCTFail("expected success response")
                        return
                }
                XCTAssertEqual(response.simInfo, SIMInfo(mcc: mcc, mnc: mnc))
                XCTAssertEqual(response.loginHintToken, hintToken)
        }

        let url = URL(string: "foo://test?mccmnc=\(mcc)\(mnc)&state=test-state&login_hint_token=\(hintToken)")!
        let didResolve = mobileNetworkSelectionService.resolve(url: url)
        XCTAssertTrue(didResolve)
        wait(for: [expectation], timeout: timeout)
    }

    func testConcludesWithSuccessNilHintToken() {
        let mcc = "123"
        let mnc = "456"
        let expectation = XCTestExpectation(description: "wait")
        mobileNetworkSelectionService.requestUserNetworkSelection(
            fromResource: MobileNetworkSelectionServiceTests.resource,
            fromCurrentViewController: MockWindowViewController()) { result in
                defer { expectation.fulfill() }
                guard
                    case .networkInfo(let response) = result else {
                        XCTFail("expected success response")
                        return
                }

                XCTAssertEqual(response.simInfo, SIMInfo(mcc: mcc, mnc: mnc))
                XCTAssertNil(response.loginHintToken)
        }
        let url = URL(string: "foo://test?mccmnc=\(mcc)\(mnc)&state=test-state")!
        let didResolve = mobileNetworkSelectionService.resolve(url: url)
        XCTAssertTrue(didResolve)
        wait(for: [expectation], timeout: timeout)
    }
}

// swiftlint:disable:next type_name
class MobileNetworkSelectionServiceRequestTests: XCTestCase {
    func testRequestCretatesAppropriatelyFormattedURL() {
        let request = MobileNetworkSelectionService.Request(
            resource: URL(string: "https://rightpoint")!,
            clientId: "foobar",
            redirectURI: "foo://pv",
            state: "?@=$somechars"
        )

        let expectedURL = URL(
            string: "https://rightpoint?client_id=foobar&redirect_uri=foo://pv&state=?@%3D$somechars"
            )!
        XCTAssertEqual(request.url, expectedURL)
    }
}

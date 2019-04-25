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

//class MockViewController: UIViewController {
//    var lastControllerPresented: UIViewController?
//    func clearMock() {
//        lastControllerPresented = nil
//    }
//
//    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
//        lastControllerPresented = viewControllerToPresent
//        DispatchQueue.main.async {
//            completion?()
//        }
//    }
//
//    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
//        DispatchQueue.main.async {
//            completion?()
//        }
//    }
//}

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

class MobileNetworkSelectionServiceTests: XCTestCase {

    static let resource = URL(string: "https://app.xcijv.com/ui/discovery-ui")!

    static let mockClientId = "mockClientId"
    let mockSDKConfig = SDKConfig(
        clientId: MobileNetworkSelectionServiceTests.mockClientId,
        redirectScheme: MobileNetworkSelectionServiceTests.mockClientId
    )

    let mockMobileNetworkSelectionUI = MockMobileNetworkSelectionUI()

    lazy var mobileNetworkSelectionService = MobileNetworkSelectionService(
        sdkConfig: mockSDKConfig,
        mobileNetworkSelectionUI: mockMobileNetworkSelectionUI
    )

    func testCallsMobileNetworkSelectionUIWithViewController() {
        let controller = UIViewController()
        mobileNetworkSelectionService.requestUserNetworkSelection(
            fromResource: MobileNetworkSelectionServiceTests.resource,
            fromCurrentViewController: controller) { _ in }
        XCTAssertTrue(mockMobileNetworkSelectionUI.lastViewController === controller)
    }

    func testCorrectSafariControllerURL() {
        let controller = UIViewController()
        mobileNetworkSelectionService.requestUserNetworkSelection(
            fromResource: MobileNetworkSelectionServiceTests.resource,
            fromCurrentViewController: controller) { _ in }
        let expectedURL = URL(string: "https://app.xcijv.com/ui/discovery-ui?client_id=mockClientId&redirect_uri=mockClientId://projectverify/discoveryui&state=test-state")!
        XCTAssertEqual(mockMobileNetworkSelectionUI.lastURL, expectedURL)
    }

    func testDuplicateRequestsCancelsPrevious() {
        mobileNetworkSelectionService.requestUserNetworkSelection(
            fromResource: MobileNetworkSelectionServiceTests.resource,
            fromCurrentViewController: UIViewController()) { result in
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

    func testConcludesWithErrorForMismatchState() {
        let expectation = XCTestExpectation(description: "wait")
        mobileNetworkSelectionService.requestUserNetworkSelection(
            fromResource: MobileNetworkSelectionServiceTests.resource,
            fromCurrentViewController: UIViewController()) { result in
                defer { expectation.fulfill() }
                guard case .error(let error) = result,
                    case MobileNetworkSelectionError.stateMismatch = error  else {
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
            fromCurrentViewController: UIViewController()) { result in
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

    }

    func testConcludesWithErrorForInvlaidLoginHintTokenIfPresent() {

    }
}

class MobileNetworkSelectionServiceRequestTests: XCTestCase {

    func testRequestCretatesAppropriatelyFormattedURL() {

    }
}

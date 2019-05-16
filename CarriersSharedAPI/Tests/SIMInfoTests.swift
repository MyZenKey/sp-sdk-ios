//
//  SIMInfoTests.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/22/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest
@testable import CarriersSharedAPI

struct MockCodes {
    struct MCC {
        // swiftlint:disable:next identifier_name
        static let us = "310"
        static let secondaryUS = "311"
    }
    struct MNC {
        static let tmobile = "160"
        static let att = "007"
        static let sprint = "120"
        static let verizon = "010"
        static let secondaryVerizon = "110"
    }
}

class SIMInfoTests: XCTestCase {

    func carrierUsingBundledLookup(_ simInfo: SIMInfo) -> Carrier {
        return simInfo.carrier(usingCarrierLookUp: NetworkIdentifierCache.bundledCarrierLookup)
    }

    func testCreatesTMobileInfo() {
        let info = SIMInfo(mcc: MockCodes.MCC.us, mnc: MockCodes.MNC.tmobile)
        XCTAssertEqual(carrierUsingBundledLookup(info), .tmobile)
    }

    func testCreatesATTInfo() {
        let info = SIMInfo(mcc: MockCodes.MCC.us, mnc: MockCodes.MNC.att)
        XCTAssertEqual(carrierUsingBundledLookup(info), .att)
    }

    func testCreatesVerizonInfo() {
        let info = SIMInfo(mcc: MockCodes.MCC.us, mnc: MockCodes.MNC.verizon)
        XCTAssertEqual(carrierUsingBundledLookup(info), .verizon)
    }

    func testCreatesSprintInfo() {
        let info = SIMInfo(mcc: MockCodes.MCC.us, mnc: MockCodes.MNC.sprint)
        XCTAssertEqual(carrierUsingBundledLookup(info), .sprint)
    }

    func testCreatesUnknownCode() {
        let info = SIMInfo(mcc: "999", mnc: "333")
        XCTAssertEqual(carrierUsingBundledLookup(info), .unknown)
    }

    func testDoesntRecognizeInvalidComboInfo() {
        let incorrectInfo = SIMInfo(mcc: MockCodes.MCC.secondaryUS, mnc: MockCodes.MNC.verizon)
        XCTAssertEqual(carrierUsingBundledLookup(incorrectInfo), .unknown)

        let correctInfo = SIMInfo(mcc: MockCodes.MCC.secondaryUS, mnc: MockCodes.MNC.secondaryVerizon)
        XCTAssertEqual(carrierUsingBundledLookup(correctInfo), .verizon)
    }
}

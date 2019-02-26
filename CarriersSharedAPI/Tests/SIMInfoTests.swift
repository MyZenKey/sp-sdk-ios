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
    func testCreatesSIMInfoWithPassedIdentifiers() {
        let info = SIMInfo(mcc: MockCodes.MCC.us, mnc: MockCodes.MNC.tmobile)
        XCTAssertEqual(info.identifiers.mcc, MockCodes.MCC.us)
        XCTAssertEqual(info.identifiers.mnc, MockCodes.MNC.tmobile)
    }

    func testCreatesTMobileInfo() {
        let info = SIMInfo(mcc: MockCodes.MCC.us, mnc: MockCodes.MNC.tmobile)
        XCTAssertEqual(info.carrier, .tmobile)
    }

    func testCreatesATTInfo() {
        let info = SIMInfo(mcc: MockCodes.MCC.us, mnc: MockCodes.MNC.att)
        XCTAssertEqual(info.carrier, .att)
    }

    func testCreatesVerizonInfo() {
        let info = SIMInfo(mcc: MockCodes.MCC.us, mnc: MockCodes.MNC.verizon)
        XCTAssertEqual(info.carrier, .verizon)
    }

    func testCreatesSprintInfo() {
        let info = SIMInfo(mcc: MockCodes.MCC.us, mnc: MockCodes.MNC.sprint)
        XCTAssertEqual(info.carrier, .sprint)
    }

    func testCreatesUnknownCode() {
        let info = SIMInfo(mcc: "999", mnc: "333")
        XCTAssertEqual(info.carrier, .unknown)
    }

    func testDoesntRecognizeInvalidComboInfo() {
        let incorrectInfo = SIMInfo(mcc: MockCodes.MCC.secondaryUS, mnc: MockCodes.MNC.verizon)
        XCTAssertEqual(incorrectInfo.carrier, .unknown)

        let correctInfo = SIMInfo(mcc: MockCodes.MCC.secondaryUS, mnc: MockCodes.MNC.secondaryVerizon)
        XCTAssertEqual(correctInfo.carrier, .verizon)
    }
}

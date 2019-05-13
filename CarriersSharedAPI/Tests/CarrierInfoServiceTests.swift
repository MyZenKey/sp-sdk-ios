//
//  CarrierInfoServiceTests.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/22/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest
@testable import CarriersSharedAPI

class CarriersInfoServiceTests: XCTestCase {

    let mockSIMA = MockSIMs.unknown
    let mockSIMB = MockSIMs.att

    let mockNetworkProvider = MockMobileNetworkInfoProvider()
    lazy var carrerInfoService: CarrierInfoService =  CarrierInfoService(
        mobileNetworkInfoProvder: self.mockNetworkProvider
    )

    override func setUp() {
        super.setUp()
        mockNetworkProvider.clear()
    }

    func testDoesntHaveSIM() {
        mockNetworkProvider.currentSIMs = []
        carrerInfoService.refreshSIMs()
        XCTAssertFalse(carrerInfoService.hasSIM)
    }

    func testReturnNilIfNoSIM() {
        mockNetworkProvider.currentSIMs = []
        carrerInfoService.refreshSIMs()
        XCTAssertNil(carrerInfoService.primarySIM)
    }

    func testHasSIM() {
        mockNetworkProvider.currentSIMs = [
            mockSIMA,
        ]
        carrerInfoService.refreshSIMs()
        XCTAssertTrue(carrerInfoService.hasSIM)
    }

    func testPrimarySIM() {
        mockNetworkProvider.currentSIMs = [
            mockSIMA,
        ]
        carrerInfoService.refreshSIMs()
        XCTAssertEqual(carrerInfoService.primarySIM, mockSIMA)
    }

    func testUseFirstSIMAsPrimarySIM() {
        mockNetworkProvider.currentSIMs = [
            mockSIMB,
            mockSIMA,
        ]
        carrerInfoService.refreshSIMs()
        XCTAssertEqual(carrerInfoService.primarySIM, mockSIMB)
    }

    func testUpdateSIMSOnNetworkInfoChanged() {
        mockNetworkProvider.currentSIMs = [
            mockSIMB,
            mockSIMA,
        ]
        carrerInfoService.refreshSIMs()
        XCTAssertEqual(carrerInfoService.primarySIM, mockSIMB)
        mockNetworkProvider.onNetworkInfoDidUpdate?([mockSIMA])
        XCTAssertEqual(carrerInfoService.primarySIM, mockSIMA)
    }
}

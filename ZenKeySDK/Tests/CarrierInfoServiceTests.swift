//
//  CarrierInfoServiceTests.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/22/19.
//  Copyright © 2019 ZenKey, LLC. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest
@testable import ZenKeySDK

class CarriersInfoServiceTests: XCTestCase {

    let mockSIMA = MockSIMs.unknown
    let mockSIMB = MockSIMs.att

    let mockNetworkProvider = MockMobileNetworkInfoProvider()
    lazy var carrerInfoService: CarrierInfoService =  CarrierInfoService(
        mobileNetworkInfoProvider: self.mockNetworkProvider
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

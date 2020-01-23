//
//  MockCarrierInfoService.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/28/19.
//  Copyright © 2019 ZenKey, LLC. All rights reserved.
//

import Foundation
@testable import ZenKeySDK

class MockCarrierInfoService: CarrierInfoServiceProtocol {
    var primarySIM: SIMInfo?
}

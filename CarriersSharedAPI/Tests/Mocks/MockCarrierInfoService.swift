//
//  MockCarrierInfoService.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/28/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
@testable import CarriersSharedAPI

class MockCarrierInfoService: CarrierInfoServiceProtocol {
    var primarySIM: SIMInfo?
}

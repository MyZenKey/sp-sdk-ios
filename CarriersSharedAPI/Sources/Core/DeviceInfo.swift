//
//  DeviceInfo.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 7/31/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

protocol DeviceInfoProtocol {
    var isTablet: Bool { get }
}

struct DeviceInfo: DeviceInfoProtocol {
    var isTablet: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}

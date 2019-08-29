//
//  BuildInfoUtilities.swift
//  Example Apps
//
//  Created by Adam Tierney on 7/11/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import Foundation
import ZenKeySDK

struct BuildInfo {

    private static let hostToggleKey = "qaHost"

    static var isQAHost: Bool {
        return UserDefaults.standard.value(forKey: hostToggleKey) != nil
    }

    static func toggleHost() {
        guard !isQAHost else  {
            UserDefaults.standard.set(nil, forKey: hostToggleKey)
            return
        }
        UserDefaults.standard.set(true, forKey: hostToggleKey)
    }

    static var zenKeyOptions: ZenKeyOptions {
        var options: ZenKeyOptions = [:]
        if isQAHost {
            options[.qaHost] = true
        }
        if let mockCarrier = ProcessInfo.processInfo.environment["ZENKEY_MOCK_CARRIER"],
            let value = Carrier(rawValue: mockCarrier) {
            options[.mockedCarrier] = value
        }
        options[.logLevel] = Log.Level.info
        return options
    }

    static func makeWatermarkLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false

        let illustrationText = "For illustration purposes only"
        let serverText: String? = isQAHost ? "Connected to QA Server" : nil
        label.text = [illustrationText, serverText]
            .compactMap() { $0 }
            .joined(separator: "\n")
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }
}

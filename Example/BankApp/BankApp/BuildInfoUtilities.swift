//
//  BuildInfoUtilities.swift
//  BankApp
//
//  Created by Adam Tierney on 7/11/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import Foundation
import CarriersSharedAPI

struct BuildInfo {

    private static let hostToggleKey =  "qaHost"

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

    static var projectVerifyOptions: ProjectVerifyOptions {
        var options: ProjectVerifyOptions = [:]
        if isQAHost {
            options[.qaHost] = true
        }
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

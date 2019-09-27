//
//  UITestLaunchArguments.swift
//  BankApp
//
//  Created by Andrew McKnight on 7/31/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import Foundation

enum UITestLaunchArgument: String {
    case loggedOut = "--logged-out"
    case mockAppBackend = "--mocked-backend"

    static func handle() {
        CommandLine.arguments.forEach {
            guard let arg = UITestLaunchArgument(rawValue: $0) else { return }
            switch arg {
            case .loggedOut:
                AccountManager.logout()
                UserAccountStorage.clearUser()

            case .mockAppBackend:
                BuildInfo.setServiceProviderHost(.mocked)
            }
        }
    }
}

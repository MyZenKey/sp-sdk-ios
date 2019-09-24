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

    enum ServiceProviderHost: Int {
        case mocked, client, ube
    }

    private static let hostToggleKey = "qaHost"
    private static let serviceProviderHostKey = "serviceProviderHost"
    private static let authModeKey = "authModeKey"

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

    static var serviceProviderHost: ServiceProviderHost {
        let hostValue = UserDefaults.standard.integer(forKey: serviceProviderHostKey)
        guard let host =  ServiceProviderHost(rawValue: hostValue) else {
            return .mocked
        }
        return host
    }

    static func setServiceProviderHost(_ host: ServiceProviderHost) {
        UserDefaults.standard.set(host.rawValue, forKey: serviceProviderHostKey)
    }

    static var currentAuthMode: ACRValue {
        let authString = UserDefaults.standard.string(forKey: authModeKey)
        if let authStringUnwrapped = authString {
            return ACRValue(rawValue: authStringUnwrapped) ?? .aal1
        } else {
            return .aal1
        }
    }

    static func setAuthMode(_ newMode: ACRValue) {
        UserDefaults.standard.set(newMode.rawValue, forKey: authModeKey)
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

    static func makeWatermarkLabel(lightText: Bool = false) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false

        let illustrationText = "For illustration purposes only"
        let serverText: String? = isQAHost ? "Connected to QA Server" : nil
        let showHostString = serviceProviderHost != .ube
        let demoAppServiceText: String? = showHostString ? "Demo App Service \(serviceProviderHost)" : nil
        label.text = [illustrationText, serverText, demoAppServiceText]
            .compactMap() { $0 }
            .joined(separator: "\n")
        label.textAlignment = .center
        label.numberOfLines = 0
        if lightText {
            label.textColor = .white
        }
        return label
    }

    static func serviceProviderAPI() -> ServiceProviderAPIProtocol {
        switch serviceProviderHost {
        case .mocked:
            return MockService()
        case .client:
            return ClientSideService()
        case .ube:
            return UniversalBackendService()
        }
    }
}

extension BuildInfo.ServiceProviderHost {
    var behaviorDescription: String {
        switch self {
        case .mocked:
            return "Mock All Success"
        case .client:
            return "Make Requests From Client App"
        case .ube:
            return "Use the Universal Backend"
        }
    }
}

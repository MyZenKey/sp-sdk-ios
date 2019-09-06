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
    private static let mockDemoServiceKey = "bankAppMockServiceKey"

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

    static var isMockDemoService: Bool {
        return UserDefaults.standard.value(forKey: mockDemoServiceKey) != nil
    }

    static func toggleMockDemoService() {
        guard !isMockDemoService else  {
            UserDefaults.standard.set(nil, forKey: mockDemoServiceKey)
            return
        }
        UserDefaults.standard.set(true, forKey: mockDemoServiceKey)
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
        let demoAppServiceText: String? = isMockDemoService ? "Mocking Demo App Service" : nil
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
        if isMockDemoService {
            return MockAuthService()
        } else {
            return ClientSideServiceAPI()
        }
    }
}

class DebugController {

    static func addMenu(toView view: UIView) {
        let debugGesture = UITapGestureRecognizer(target: self, action: #selector(show))
        debugGesture.numberOfTapsRequired = 3
        debugGesture.numberOfTouchesRequired = 2
        view.addGestureRecognizer(debugGesture)
    }

    static func addMenu(toViewController viewController: UIViewController) {
        addMenu(toView: viewController.view)
    }

    static var actions: [UIAlertAction] {
        return [
            UIAlertAction(
                title: "Mock Bank App Host: is \(BuildInfo.isMockDemoService)",
                style: .default,
                handler: { _ in BuildInfo.toggleMockDemoService() }
            ),
            UIAlertAction(
                title: "Toggle JV Host (will force quit app)",
                style: .default,
                handler: { _ in
                    BuildInfo.toggleHost()
                    fatalError("restarting app")
                }
            ),
            UIAlertAction(
                title: "Cancel",
                style: .cancel,
                handler: nil
            ),
        ]
    }

    @objc static func show() {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate,
            let rootViewController = delegate.window?.rootViewController else {
                return
        }

        var topMostViewController: UIViewController? = rootViewController
        while topMostViewController?.presentedViewController != nil {
            topMostViewController = topMostViewController?.presentedViewController!
        }

        let controller = UIAlertController(
            title: "Debug Menu",
            message: nil,
            preferredStyle: .actionSheet
        )

        DebugController.actions.forEach() { controller.addAction($0) }

        topMostViewController?.present(controller, animated: true, completion: nil)
    }
}

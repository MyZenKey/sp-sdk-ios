//
//  MobileNetworkSelectionService.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 4/16/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import SafariServices
import UIKit

enum MobileNetworkSelectionUIResult {
    case networkInfo(SIMInfo)
    case cancelled
    case error
}

typealias MobileNetworkSelectionCompletion = (MobileNetworkSelectionUIResult) -> Void

protocol MobileNetworkSelectionServiceProtocol {
    func requestUserNetworkSelection(
        fromCurrentViewController viewController: UIViewController,
        completion: @escaping MobileNetworkSelectionCompletion
    )

    func conclude(withURL url: URL)
}

class MobileNetworkSelectionService: NSObject, MobileNetworkSelectionServiceProtocol {
    //client_id=ccid-SP0001&redirect_uri=https:%2F%2Fclient.example.org%2Fcb&state=testabc
    private var state: State = .idle
    private var completion: MobileNetworkSelectionCompletion?
    private var sdkConfig: SDKConfig {
        return ProjectVerifyAppDelegate.shared.sdkConfig
    }

    override init() {
        super.init()
    }

    func requestUserNetworkSelection(
        fromCurrentViewController viewController: UIViewController,
        completion: @escaping ((MobileNetworkSelectionUIResult) -> Void)) {

        self.completion = completion

        let request = Request(
            clientId: sdkConfig.clientId,
            redirectURI: sdkConfig.redirectURL(forRoute: .discoveryUI).absoluteString,
            state: "test-state"
        )

        let safariController = SFSafariViewController(
            url: request.url
        )

        safariController.delegate = self

        if #available(iOS 11.0, *) {
            safariController.dismissButtonStyle = .cancel
        } else {
            // TOOD: Fallback on earlier versions

        }

        viewController.present(safariController, animated: true, completion: nil)
    }

    func conclude(withURL url: URL) {

    }
}

extension MobileNetworkSelectionService {

    enum State {
        case requesting, idle
    }

    struct Request {
        let clientId: String
        let redirectURI: String
        let state: String

        var url: URL {
            var builder = URLComponents(string: "https://xci-demoapp-node.raizlabs.xyz/mock/discovery-ui")
            builder?.queryItems = [
                URLQueryItem(name: "client_id", value: clientId),
                URLQueryItem(name: "redirect_uri", value: redirectURI),
                URLQueryItem(name: "state", value: state),
            ]

            guard
                let components = builder,
                let url = components.url
                else {
                    fatalError("unable to assemble correct url for discovery-ui request \(self)")
            }

            return url
        }
    }
}

extension MobileNetworkSelectionService: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        completion?(.cancelled)
    }
}

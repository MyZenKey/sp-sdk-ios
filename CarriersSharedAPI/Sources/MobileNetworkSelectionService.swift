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
    case error(MobileNetworkSelectionUIError)
    case cancelled
}

enum MobileNetworkSelectionUIError: Error {
    case invalidMCCMNC
    case stateMismatch
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

    private enum Keys: String {
        case mccmnc
    }
    //client_id=ccid-SP0001&redirect_uri=https:%2F%2Fclient.example.org%2Fcb&state=testabc
    private var state: State = .idle
    private var sdkConfig: SDKConfig {
        return ProjectVerifyAppDelegate.shared.sdkConfig
    }

    override init() {
        super.init()
    }

    func requestUserNetworkSelection(
        fromCurrentViewController viewController: UIViewController,
        completion: @escaping ((MobileNetworkSelectionUIResult) -> Void)) {

        guard case .idle = state else {
            // complete any pending request with implicit cancellation
            if case .requesting(_, let completion) = state {
                completion(.cancelled)
            }
            return
        }

        let request = Request(
            clientId: sdkConfig.clientId,
            redirectURI: sdkConfig.redirectURL(forRoute: .discoveryUI).absoluteString,
            // TODO: better states:
            state: "test-state"
        )

        state = .requesting(request, completion)

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
        guard case .requesting(let request, _) = state else {
            // no request in progress
            return
        }

        let response = ResponseURL(url: url)
        guard response.hasMatchingState(request.state) else {
            // completion mis match state error
            conclude(result: .error(.stateMismatch))
            return
        }

        guard
            let mccmnc = response[Keys.mccmnc.rawValue],
            mccmnc.count == 6
            else {
                conclude(result: .error(.invalidMCCMNC))
            return
        }

        let simInfo = mccmnc.toSIMInfo()
        conclude(result: .networkInfo(simInfo))
    }

    private func conclude(result: MobileNetworkSelectionUIResult) {
        defer { state = .idle }
        guard case .requesting(_, let completion) = state else {
            return
        }

        completion(result)
    }
}

extension MobileNetworkSelectionService {
    enum State {
        case requesting(Request, MobileNetworkSelectionCompletion), idle
    }

    struct Request {
        let clientId: String
        let redirectURI: String
        let state: String
    }
}

extension MobileNetworkSelectionService: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        conclude(result: .cancelled)
    }
}

extension MobileNetworkSelectionService.Request {

    enum Params: String {
        case clientId = "client_id"
        case redirectURI = "redirect_uri"
        case state
    }

    var url: URL {
        // TODO: host config
        var builder = URLComponents(string: "https://xci-demoapp-node.raizlabs.xyz/mock/discovery-ui")
        builder?.queryItems = [
            URLQueryItem(name: Params.clientId.rawValue, value: clientId),
            URLQueryItem(name: Params.redirectURI.rawValue, value: redirectURI),
            URLQueryItem(name: Params.state.rawValue, value: state),
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

extension String {
    func toSIMInfo() -> SIMInfo {
        precondition(count == 6, "only strings of 6 characters can be converted to SIMInfo")
        var copy = self
        let mnc = copy.popLast(3)
        let mcc = copy.popLast(3)
        return SIMInfo(mcc: String(mcc), mnc: String(mnc))
    }


    /// removes and returns the last n characters from the string
    private mutating func popLast(_ n: Int) -> Substring {
        let bounded = min(n, count)
        let substring = suffix(bounded)
        removeLast(bounded)
        return substring
    }
}

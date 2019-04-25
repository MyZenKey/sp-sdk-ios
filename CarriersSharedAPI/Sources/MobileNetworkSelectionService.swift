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

protocol MobileNetworkSelectionServiceProtocol: URLHandling {
    func requestUserNetworkSelection(
        fromResource resource: URL,
        fromCurrentViewController viewController: UIViewController,
        completion: @escaping MobileNetworkSelectionCompletion
    )
}

class MobileNetworkSelectionService: NSObject, MobileNetworkSelectionServiceProtocol {

    private var state: State = .idle
    private var sdkConfig: SDKConfig {
        return ProjectVerifyAppDelegate.shared.sdkConfig
    }

    override init() {
        super.init()
    }

    func requestUserNetworkSelection(
        fromResource resource: URL,
        fromCurrentViewController viewController: UIViewController,
        completion: @escaping ((MobileNetworkSelectionUIResult) -> Void)) {

        guard case .idle = state else {
            // complete any pending request with implicit cancellation
            if case .requesting(_, _, _) = state {
                conclude(result: .cancelled)
            }
            return
        }

        let request = Request(
            resource: resource,
            clientId: sdkConfig.clientId,
            redirectURI: sdkConfig.redirectURL(forRoute: .discoveryUI).absoluteString,
            // TODO: better states:
            state: "test-state"
        )

        let safariController = SFSafariViewController(
            url: request.url
        )

        state = .requesting(request, safariController, completion)

        safariController.delegate = self

        if #available(iOS 11.0, *) {
            safariController.dismissButtonStyle = .cancel
        }

        viewController.present(safariController, animated: true, completion: nil)
    }

    func resolve(url: URL) -> Bool {
        guard case .requesting(let request, _, _) = state else {
            // no request in progress
            return false
        }

        resolve(request: request, withURL: url)
        return true
    }
}

extension MobileNetworkSelectionService {
    enum State {
        case requesting(Request, SFSafariViewController, MobileNetworkSelectionCompletion)
        case idle
    }

    struct Request {
        ///  the discovery ui resource ie. "https://app.xcijv.com/ui/discovery-ui"
        let resource: URL
        let clientId: String
        let redirectURI: String
        let state: String
    }
}

private extension MobileNetworkSelectionService {
    enum Keys: String {
        case mccmnc
    }

    func resolve(request: Request, withURL url: URL) {
        let response = ResponseURL(url: url)

        // FIXME: jv endpoint isn't yet reflecting the state param
//        guard response.hasMatchingState(request.state) else {
//            // completion mis match state error
//            conclude(result: .error(.stateMismatch))
//            return
//        }

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

    func conclude(result: MobileNetworkSelectionUIResult, cleanupController: Bool = true) {
        guard case .requesting(_, let controller, let completion) = state else {
            return
        }

        if cleanupController {
            // remove the view controller and then invoke completion:
            controller.dismiss(
                animated: true,
                completion: {
                    completion(result)
                    self.state = .idle
            })
        } else {
            completion(result)
            state = .idle
        }
    }
}

extension MobileNetworkSelectionService: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        // don't clean up, user dismissed the controller, it will be cleaned up, there is no race
        conclude(result: .cancelled, cleanupController: false)
    }
}

extension MobileNetworkSelectionService.Request {
    enum Params: String {
        case clientId = "client_id"
        case redirectURI = "redirect_uri"
        case state
    }

    var url: URL {
        var builder = URLComponents(url: resource, resolvingAgainstBaseURL: false)
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

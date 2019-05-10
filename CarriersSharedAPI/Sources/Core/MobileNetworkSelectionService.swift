//
//  MobileNetworkSelectionService.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 4/16/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

struct MobileNetworkSelectionResponse {
    let simInfo: SIMInfo
    let loginHintToken: String?
}

enum MobileNetworkSelectionResult {
    case networkInfo(MobileNetworkSelectionResponse)
    case error(MobileNetworkSelectionError)
    case cancelled
}

enum MobileNetworkSelectionError: Error {
    case invalidMCCMNC
    case urlResponseError(URLResponseError)
}

typealias MobileNetworkSelectionCompletion = (MobileNetworkSelectionResult) -> Void

protocol MobileNetworkSelectionServiceProtocol: URLHandling {
    func requestUserNetworkSelection(
        fromResource resource: URL,
        fromCurrentViewController viewController: UIViewController,
        completion: @escaping MobileNetworkSelectionCompletion
    )
}

class MobileNetworkSelectionService: NSObject, MobileNetworkSelectionServiceProtocol {

    private var state: State = .idle
    private let sdkConfig: SDKConfig
    private let mobileNetworkSelectionUI: MobileNetworkSelectionUIProtocol


    init(sdkConfig: SDKConfig, mobileNetworkSelectionUI: MobileNetworkSelectionUIProtocol) {
        self.sdkConfig = sdkConfig
        self.mobileNetworkSelectionUI = mobileNetworkSelectionUI
        super.init()
    }

    func requestUserNetworkSelection(
        fromResource resource: URL,
        fromCurrentViewController viewController: UIViewController,
        completion: @escaping ((MobileNetworkSelectionResult) -> Void)) {

        guard case .idle = state else {
            dismissUI {
                self.conclude(result: .cancelled)
                self.requestUserNetworkSelection(
                    fromResource: resource,
                    fromCurrentViewController: viewController,
                    completion: completion)
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

        state = .requesting(request, completion)

        mobileNetworkSelectionUI.showMobileNetworkSelectionUI(
            fromController: viewController,
            usingURL: request.url,
            onUIDidCancel: { [weak self] in
                // ui triggered the dismissal and will clean itself up, just call the completion
                self?.conclude(result: .cancelled)
        })
    }

    func resolve(url: URL) -> Bool {
        guard case .requesting(let request, _) = state else {
            // no request in progress
            return false
        }

        resolve(request: request, withURL: url)
        return true
    }
}

extension MobileNetworkSelectionService {
    enum State {
        case requesting(Request, MobileNetworkSelectionCompletion)
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
        case loginHintToken = "login_hint_token"
    }

    func resolve(request: Request, withURL url: URL) {
        let response = ResponseURL(url: url)

        // FIXME: jv endpoint isn't yet reflecting the state param, comment in when done
//        // promotes URLResponseError into a MobileNetworkSelectionFlowError
//        let validatedSIMInfoResult = response.hasMatchingState(request.state).promoteResult()
//            // check error
//            .flatMap({ response.getError().promoteResult() })
        let validatedSIMInfoResult = response.getError().promoteResult()
            // parse mcc/mnc value
            .flatMap({ response.getRequiredValue(Keys.mccmnc.rawValue).promoteResult() })
            // map to sim info
            .flatMap({ mccmnc in return mccmnc.toSIMInfo() })

        let loginHintToken: String? = response[Keys.loginHintToken.rawValue]

        switch validatedSIMInfoResult {
        case .value(let simInfo):
            dismissUIAndConclude(result: .networkInfo(
                MobileNetworkSelectionResponse(
                    simInfo: simInfo,
                    loginHintToken: loginHintToken
                )
            ))

        case .error(let error):
            dismissUIAndConclude(result: .error(error))
        }
    }

    func dismissUI(completion: @escaping () -> Void) {
        mobileNetworkSelectionUI.close {
            completion()
        }
    }

    func conclude(result: MobileNetworkSelectionResult) {
        defer { state = .idle }
        guard case .requesting(_, let completion) = state else {
            return
        }
        completion(result)
    }

    func dismissUIAndConclude(result: MobileNetworkSelectionResult) {
        dismissUI {
            self.conclude(result: result)
        }
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

private extension String {
    func toSIMInfo() -> Result<SIMInfo, MobileNetworkSelectionError> {
        guard count == 6 else {
            return .error(.invalidMCCMNC)
        }
        var copy = self
        let mnc = copy.popLast(3)
        let mcc = copy.popLast(3)
        return .value(SIMInfo(mcc: String(mcc), mnc: String(mnc)))
    }

    /// removes and returns the last n characters from the string
    mutating func popLast(_ n: Int) -> Substring {
        let bounded = min(n, count)
        let substring = suffix(bounded)
        removeLast(bounded)
        return substring
    }
}

// MARK: - Error Mapping

private extension Result where E == URLResponseError {
    func promoteResult() -> Result<T, MobileNetworkSelectionError> {
        switch self {
        case .value(let value):
            return .value(value)
        case .error(let error):
            return .error(.urlResponseError(error))
        }
    }
}

//
//  MobileNetworkSelectionService.swift
//  ZenKeySDK
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
    case viewControllerNotInHeirarchy
    case invalidMCCMNC
    case urlResponseError(URLResponseError)
    case stateError(RequestStateError)
}

typealias MobileNetworkSelectionCompletion = (MobileNetworkSelectionResult) -> Void

protocol MobileNetworkSelectionServiceProtocol: URLHandling {
    func requestUserNetworkSelection(
        fromResource resource: URL,
        fromCurrentViewController viewController: UIViewController,
        prompt: Bool,
        completion: @escaping MobileNetworkSelectionCompletion
    )
}

class MobileNetworkSelectionService: NSObject, MobileNetworkSelectionServiceProtocol {

    private var state: State = .idle
    private let sdkConfig: SDKConfig
    private let mobileNetworkSelectionUI: MobileNetworkSelectionUIProtocol
    private let stateGenerator: () -> String?

    init(sdkConfig: SDKConfig,
         mobileNetworkSelectionUI: MobileNetworkSelectionUIProtocol,
         stateGenerator: @escaping () -> String? = RandomStringGenerator.generateStateSuitableString) {
        self.sdkConfig = sdkConfig
        self.mobileNetworkSelectionUI = mobileNetworkSelectionUI
        self.stateGenerator = stateGenerator
        super.init()
    }

    func requestUserNetworkSelection(
        fromResource resource: URL,
        fromCurrentViewController viewController: UIViewController,
        prompt: Bool = false,
        completion: @escaping ((MobileNetworkSelectionResult) -> Void)) {

        guard case .idle = state else {
            Log.log(.warn, "Implictly cancelling existing request.")
            dismissUI {
                self.conclude(result: .cancelled)
                self.requestUserNetworkSelection(
                    fromResource: resource,
                    fromCurrentViewController: viewController,
                    completion: completion)
            }
            return
        }

        guard viewController.view?.window != nil else {
            completion(.error(.viewControllerNotInHeirarchy))
            return
        }

        guard let stateParam = stateGenerator() else {
            completion(.error(.stateError(.generationFailed)))
            return
        }

        let request = Request(
            resource: resource,
            clientId: sdkConfig.clientId,
            redirectURI: sdkConfig.redirectURL.absoluteString,
            state: stateParam,
            prompt: prompt
        )

        state = .requesting(request, completion)

        Log.log(.info, "Display ui with request: \(request.url)")
        mobileNetworkSelectionUI.showMobileNetworkSelectionUI(
            fromController: viewController,
            usingURL: request.url,
            onUIDidCancel: { [weak self] in
                // ui triggered the dismissal and will clean itself up, just call the completion
                self?.conclude(result: .cancelled)
        })
    }

    func cancel() {
        dismissUIAndConclude(result: .cancelled)
    }

    func resolve(url: URL) -> Bool {
        guard case .requesting(let request, _) = state else {
            // no request in progress
            Log.log(.warn, "Attempting to resolve url \(url) with no request in progress")
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
        ///  the discovery ui resource ie. "https://app.myzenkey.com/ui/discovery-ui"
        let resource: URL
        let clientId: String
        let redirectURI: String
        let state: String
        let prompt: Bool
    }
}

private extension MobileNetworkSelectionService {
    enum Keys: String {
        case mccmnc
        case loginHintToken = "login_hint_token"
    }

    func resolve(request: Request, withURL url: URL) {
        let response = ResponseURL(url: url)

        // promotes URLResponseError into a MobileNetworkSelectionFlowError
        let validatedSIMInfoResult = response.hasMatchingState(request.state).promoteResult()
            // check error
            .flatMap({ response.getError().promoteResult() })
            // parse mcc/mnc value
            .flatMap({ response.getRequiredValue(Keys.mccmnc.rawValue).promoteResult() })
            // map to sim info
            .flatMap({ mccmnc in return mccmnc.toSIMInfo() })

        let loginHintToken: String? = response[Keys.loginHintToken.rawValue]

        switch validatedSIMInfoResult {
        case .value(let simInfo):
            Log.log(.info, "Resolving URL: \(url) with sim info: \(simInfo)")
            dismissUIAndConclude(result: .networkInfo(
                MobileNetworkSelectionResponse(
                    simInfo: simInfo,
                    loginHintToken: loginHintToken
                )
            ))

        case .error(let error):
            Log.log(.error, "Resolving URL: \(url) with error: \(error)")
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
        case prompt
    }

    var url: URL {
        var builder = URLComponents(url: resource, resolvingAgainstBaseURL: false)
        builder?.queryItems = [
            URLQueryItem(name: Params.clientId.rawValue, value: clientId),
            URLQueryItem(name: Params.redirectURI.rawValue, value: redirectURI),
            URLQueryItem(name: Params.state.rawValue, value: state),
        ]

        if prompt {
            builder?.queryItems?.append(
                URLQueryItem(name: Params.prompt.rawValue, value: String(prompt))
            )
        }

        guard
            let components = builder,
            let url = components.url
            else {
                fatalError("unable to assemble correct url for discovery-ui request \(self)")
        }

        return url
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

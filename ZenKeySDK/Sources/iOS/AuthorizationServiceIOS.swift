//
//  AuthorizationServiceIOS.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 5/3/19.
//  Copyright © 2019 ZenKey, LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

class AuthorizationServiceIOS {
    let sdkConfig: SDKConfig
    let discoveryService: DiscoveryServiceProtocol
    let openIdService: OpenIdServiceProtocol
    let carrierInfoService: CarrierInfoServiceProtocol
    let mobileNetworkSelectionService: MobileNetworkSelectionServiceProtocol
    let stateGenerator: () -> String?

    public var isAuthorizing: Bool {
        if case .idle = state {
            return false
        } else {
            return true
        }
    }

    private var state: State = .idle {
        willSet {
            precondition(Thread.isMainThread)
        }
    }

    init(sdkConfig: SDKConfig,
         discoveryService: DiscoveryServiceProtocol,
         openIdService: OpenIdServiceProtocol,
         carrierInfoService: CarrierInfoServiceProtocol,
         mobileNetworkSelectionService: MobileNetworkSelectionServiceProtocol,
         stateGenerator: @escaping () -> String? = RandomStringGenerator.generateStateSuitableString) {
        self.sdkConfig = sdkConfig
        self.discoveryService = discoveryService
        self.openIdService = openIdService
        self.carrierInfoService = carrierInfoService
        self.mobileNetworkSelectionService = mobileNetworkSelectionService
        self.stateGenerator = stateGenerator
    }
}

extension AuthorizationServiceIOS {
    enum State {
        case idle
        case requesting(AuthorizationServiceStateMachine, AuthorizationRequestContext)
    }
}

extension AuthorizationServiceIOS: AuthorizationServiceProtocolInternal {
    public func authorize(
        scopes: [ScopeProtocol],
        fromViewController viewController: UIViewController,
        acrValues: [ACRValue]? = nil,
        state: String? = nil,
        correlationId: String? = nil,
        context: String? = nil,
        prompt: PromptValue? = nil,
        nonce: String? = nil,
        theme: Theme? = nil,
        completion: @escaping AuthorizationCompletion) {

        precondition(Thread.isMainThread, "You should only call `authorize` from the main thread.")

        let parameters = OpenIdAuthorizationRequest.Parameters(
            clientId: sdkConfig.clientId,
            redirectURL: sdkConfig.redirectURL,
            formattedScopes: OpenIdScopes(requestedScopes: scopes).networkFormattedString,
            state: state,
            nonce: nonce,
            acrValues: acrValues,
            prompt: prompt,
            correlationId: correlationId,
            context: context,
            loginHintToken: nil,
            theme: theme
        )

        let stateMachine = AuthorizationServiceStateMachine(
            deviceInfoProvider: DeviceInfo(),
            onStateChange: { [weak self] _ in self?.handleStateChange() }
        )

        let requestContext = AuthorizationRequestContext(
            viewController: viewController,
            parameters: parameters,
            completion: completion
        )

        if case .requesting = self.state {
            cancel() // will always execute synchronously per precondition above.
        }

        self.state = .requesting(stateMachine, requestContext)

        preflightCheck()
    }

    public func cancel() {
        precondition(Thread.isMainThread, "You should only call `cancel` from the main thread.")
        guard case .requesting(let stateMachine, _) = state else {
            return
        }

        stateMachine.mainQueueSend(event: .cancelled)
    }
}

extension AuthorizationServiceIOS {
    func resolve(url: URL) -> Bool {
        guard case .requesting(let stateMachine, _) = state else {
            return false
        }

        switch stateMachine.state {
        case .authorization:
            return openIdService.resolve(url: url)

        case .mobileNetworkSelection:
            return mobileNetworkSelectionService.resolve(url: url)

        default:
            return false
        }
    }
}

private extension AuthorizationServiceIOS {

    func preflightCheck() {
        guard case .requesting(let stateMachine, let requestContext) = state else {
            return
        }

        guard let generatedState = stateGenerator() else {
            stateMachine.mainQueueSend(
                event: .errored(RequestStateError.generationFailed.asAuthorizationError)
            )
            return
        }
        requestContext.addState(generatedState)

        let simInfo = carrierInfoService.primarySIM
        stateMachine.mainQueueSend(event: .attemptDiscovery(simInfo))
    }

    func handleStateChange() {
        precondition(Thread.isMainThread)
        guard case .requesting(let stateMachine, let requestContext) = state else {
            return
        }

        switch stateMachine.state {
        case .idle:
            break

        case .discovery(let simInfo, let passPrompt):
            performDiscovery(with: simInfo, prompt: passPrompt)

        case .mobileNetworkSelection(let resource, let passPrompt):
            showDiscoveryUI(usingResource: resource, prompt: passPrompt)

        case .authorization(let discoveredConfig):
            showAuthorizationUI(usingConfig: discoveredConfig)

        case .concluding(let outcome):
            requestContext.completion(outcome)
            state = .idle
        }
    }
}

private extension AuthorizationServiceIOS {
    func performDiscovery(with simInfo: SIMInfo?, prompt: Bool = false) {
        guard case .requesting(let stateMachine, _) = state else {
            return
        }

        discoveryService.discoverConfig(
            forSIMInfo: simInfo,
            prompt: prompt) { result in
            switch result {
            case .knownMobileNetwork(let config):
                stateMachine.mainQueueSend(event: .discoveredConfig(config))

            case .unknownMobileNetwork(let redirect):
                stateMachine.mainQueueSend(event: .redirected(redirect.redirectURI))

            case .error(let error):
                stateMachine.mainQueueSend(event: .errored(error.asAuthorizationError))
            }
        }
    }

    func showAuthorizationUI(usingConfig config: CarrierConfig) {
        guard case .requesting(let stateMachine, let requestContext) = state else {
            return
        }

        openIdService.authorize(
            fromViewController: requestContext.viewController,
            carrierConfig: config,
            authorizationParameters: requestContext.parameters) { result in

                switch result {
                case .code(let response):
                    stateMachine.mainQueueSend(event: .authorized(response))

                case .error(let error):
                    stateMachine.mainQueueSend(event: .errored(error.asAuthorizationError))

                case .cancelled:
                    stateMachine.mainQueueSend(event: .cancelled)
                }
        }
    }

    func showDiscoveryUI(usingResource resource: URL, prompt: Bool = false) {
        guard case .requesting(let stateMachine, let requestContext) = state else {
            return
        }

        self.mobileNetworkSelectionService.requestUserNetworkSelection(
            fromResource: resource,
            fromCurrentViewController: requestContext.viewController,
            prompt: prompt
        ) { result in
            switch result {
            case .networkInfo(let response):
                requestContext.addLoginHintToken(response.loginHintToken)
                stateMachine.mainQueueSend(event: .attemptDiscovery(response.simInfo))

            case .error(let error):
                stateMachine.mainQueueSend(event: .errored(error.asAuthorizationError))

            case .cancelled:
                stateMachine.mainQueueSend(event: .cancelled)
            }
        }
    }
}

private extension AuthorizationServiceStateMachine {
    func mainQueueSend(event: AuthorizationServiceStateMachine.Event) {
        precondition(Thread.isMainThread)
        handle(event: event)
    }
}

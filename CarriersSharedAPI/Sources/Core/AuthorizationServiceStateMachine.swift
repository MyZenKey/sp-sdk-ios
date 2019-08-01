//
//  AuthorizationServiceStateMachine.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 6/7/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

enum AuthorizationStateMachineError {
    case tooManyRedirects
    case tooManyRecoveries
}

/// This class captures the state and information required during the life time of an authorization
/// request. It defines the state and validates changes to state to ensure those changes maintain
/// consistencey with the request's current state.
class AuthorizationServiceStateMachine {
    typealias StateChangeHandler = (AuthorizationServiceStateMachine) -> Void

    enum State {
        /// No defined action. Any state is a valid transition.
        case idle
        /// The next action is to perform discovery. Any state is a valid transition.
        case discovery(SIMInfo?, Bool)
        /// The next action is to perform discovery-ui. Any state is a valid transition.
        case mobileNetworkSelection(URL, Bool)
        /// The next action is to perorm authorization. Any state is a valid transition.
        case authorization(CarrierConfig)
        ///  The only valid tranistion is to the finished state.
        case concluding(AuthorizationResult)
    }

    enum Event {
        case attemptDiscovery(SIMInfo?)
        case discoveredConfig(CarrierConfig)
        case redirected(URL)
        case errored(AuthorizationError)
        case authorized(AuthorizedResponse)
        case cancelled
    }

    /// Convenience accesor indicating whether or not the request is in a finished state.
    var isFinished: Bool {
        return self.state.isConcludingState
    }

    /// If this flag is set on the request the prompt flag should be sent to all disocvery
    /// endpoints and all cookies should be ignored. If this flag is already set for a request
    /// recovery should not be attempted a second time.
    private(set) var isAttemptingMissingUserRecovery: Bool = false

    /// Request state. Use the `update(state:)` function to manipulate this value.
    private(set) var state: State = .idle {
        didSet {
            stateChangeHandler(self)
        }
    }

    /// This flag inidcates whether or not we should return `true` for pasPromptDiscovery.
    ///
    /// Discussion:
    /// Prompt is passed to discovery under the following circumstances:
    /// - pass prompt on the first discovery call if using an iPad.
    /// - pass prompt on the first discovery call if attempting missing user recovery.
    private var passPromptDiscoveryFlag = false

    /// This value indicates whether it's possbile to redirect to discovery ui. redirects are
    /// permitted one time per request unless we attempt a missing user recovery flow in which case
    /// they are premitted an addtional time.
    private var canRedirectToDiscoveryUI = true

    private let deviceInfoProvider: DeviceInfoProtocol

    private let stateChangeHandler: StateChangeHandler

    init(deviceInfoProvider: DeviceInfoProtocol,
         onStateChange: @escaping StateChangeHandler) {
        self.deviceInfoProvider = deviceInfoProvider
        self.stateChangeHandler = onStateChange
        // on tablets, always prompt discovery on the first call:
        if deviceInfoProvider.isTablet {
            passPromptDiscoveryFlag = true
        }
    }

    func handle(event: Event) {
        // Don't handle events after finshed state is reached.
        guard !isFinished else {
            return
        }

        let nextState = state(forEvent: event)
        Log.log(
            nextState.isErrorConclusion ? .error : .info,
            "State Change : From |\(state)| to |\(nextState)| via Event: |\(event)|"
        )
        state = nextState
    }
}

private extension AuthorizationServiceStateMachine {
    func state(forEvent event: Event) -> State {
        switch event {
        case .attemptDiscovery(let simInfo):
            // this flag indicates whether we should prompt to discovert ui:
            let shouldPrompt = passPromptDiscoveryFlag
            // if we've just completed discovery, we should unset this flag as it is fulfilled by a
            // single discovery call:
            passPromptDiscoveryFlag = false
            return .discovery(simInfo, shouldPrompt)

        case .discoveredConfig(let carrierConfig):
            return .authorization(carrierConfig)

        case .redirected(let url):
            // enusre we haven't redirected through ui before:
            guard canRedirectToDiscoveryUI else {
                let error = AuthorizationStateMachineError.tooManyRedirects.asAuthorizationError
                return .concluding(.error(error))
            }

            // only permit this re-direction one time:
            canRedirectToDiscoveryUI = false
            let shouldPrompt = isAttemptingMissingUserRecovery
            return .mobileNetworkSelection(url, shouldPrompt)

        case .errored(let error):
            return nextState(forError: error)

        case .authorized(let authorizedPayload):
            return .concluding(.code(authorizedPayload))

        case .cancelled:
            return .concluding(.cancelled)
        }
    }

    func nextState(forError error: AuthorizationError) -> State {
        switch error.code {
        case ProjectVerifyErrorCode.userNotFound.rawValue:
            // enusre we haven't attempted recovery before:
            guard !isAttemptingMissingUserRecovery else {
                let error = AuthorizationStateMachineError.tooManyRecoveries.asAuthorizationError
                return .concluding(.error(error))
            }

            // set a flag to indicate we're attempting user recovery, the next call to discovery-ui
            // should use prompt:
            isAttemptingMissingUserRecovery = true

            // the next *one* call to discovery should use prompt
            passPromptDiscoveryFlag = true

            // we're attemting to recover – permit redirects to discovery ui
            canRedirectToDiscoveryUI = true

            // enter discovery w/o a sim, we wil also prompt.
            return state(forEvent: .attemptDiscovery(nil))

        default:
            return .concluding(.error(error))
        }
    }
}

private extension AuthorizationServiceStateMachine.State {
    var isConcludingState: Bool {
        guard case .concluding = self else {
            return false
        }
        return true
    }

    var isErrorConclusion: Bool {
        guard
            case .concluding(let outcome) = self,
            case .error = outcome else {
            return false
        }
        return true
    }
}

// MARK: - Logging

extension AuthorizationServiceStateMachine.State: CustomStringConvertible {
    var description: String {
        switch self {
        case .idle:
            return "Idle"
        case .mobileNetworkSelection(_, let prompt):
            return "Discovery UI (prompt \(prompt))"
        case .discovery(let simInfo, let prompt):
            let suffix: String = simInfo == nil ? "no mcc/mnc" :  "for \(simInfo!)"
            return "Discovery (prompt \(prompt), " + suffix + ")"
        case .authorization:
            return "Authorization"
        case .concluding(let outcome):
            return "Finished With Outcome: \(outcome)"
        }
    }
}

extension AuthorizationServiceStateMachine.Event: CustomStringConvertible {
    var description: String {
        switch self {
        case .attemptDiscovery(let simInfo):
            let suffix: String = simInfo == nil ? "no mcc/mnc" :  "for \(simInfo!)"
            return "Attempt Discovery (" + suffix + ")"
        case .discoveredConfig:
            return "Discovered Config"
        case .redirected:
            return "Recieved Redirect"
        case .errored(let error):
            return "Errored: \(error)"
        case .authorized:
            return "Authorized"
        case .cancelled:
            return "Cancelled"
        }
    }
}

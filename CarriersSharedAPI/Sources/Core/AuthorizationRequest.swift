//
//  AuthorizationRequest.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 6/7/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

/// This class captures the state and information required during the life time of an authorization
/// request. It defines the state and validates changes to state to ensure those changes maintain
/// consistencey with the request's current state.
class AuthorizationRequest {
    enum State {
        /// No defined action. Any state is a valid transition.
        case undefined
        /// The next action is to perform discovery. Any state is a valid transition.
        case discovery(SIMInfo?)
        /// The next action is to perform discovery-ui. Any state is a valid transition.
        case mobileNetworkSelection(URL)
        /// The next action is to perorm authorization. Any state is a valid transition.
        case authorization(CarrierConfig)
        ///  Any state is a valid transition.
        case missingUserRecovery
        ///  The only valid tranistion is to  state is a valid transition.
        case concluding(AuthorizationResult)
        ///  No other state tranistions are valid.
        case finished
    }

    var isFinished: Bool {
        if case .finished = state {
            return true
        } else {
            return false
        }
    }

    /// Whether the `prompt` flag should be passed to discovery and discovery-ui
    var passPrompt: Bool {
        return isAttemptingMissingUserRecovery
    }

    /// If this flag is set on the request the prompt flag should be sent to all disocvery
    /// endpoints and all cookies should be ignored. If this flag is already set for a request
    /// recovery should not be attempted a second time.
    private(set) var isAttemptingMissingUserRecovery: Bool = false

    private(set) var state: State = .undefined {
        didSet {
            if case .missingUserRecovery = state {
                // set a flat to indicate we're attempting user recovery:
                isAttemptingMissingUserRecovery = true
            }
        }
    }

    var authorizationParameters: OpenIdAuthorizationParameters

    let viewController: UIViewController
    private let completion: AuthorizationCompletion

    init(viewController: UIViewController,
         authorizationParameters: OpenIdAuthorizationParameters,
         completion: @escaping AuthorizationCompletion) {
        self.viewController = viewController
        self.authorizationParameters = authorizationParameters
        self.completion = completion
    }

    func update(state: State) {
        // No state transition are valid after finshed is reached.
        guard !isFinished else {
            return
        }

        if case .finished = state {
            // If we are moving to a finished state, establish we have previously entered a
            // concluding state and extract the outcome.
            guard case .concluding(let outcome) = self.state else {
                fatalError("You must transition to a concluding state before a finished state.")
            }

            // ensure consistency so update state before calling completion.
            self.state = state
            // send the completion:
            completion(outcome)
        } else {
            self.state = state
        }
    }
}

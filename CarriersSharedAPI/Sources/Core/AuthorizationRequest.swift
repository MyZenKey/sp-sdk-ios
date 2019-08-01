//
//  AuthorizationRequest.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 6/7/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

enum AuthorizationRequestError {
    case tooManyRedirects
    case tooManyRecoveries
}

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
        ///  The only valid tranistion is to the finished state.
        case concluding(AuthorizationResult)
        ///  No other state tranistions are valid.
        case finished
    }

    var isFinished: Bool {
        return self.state.isFinishedState
    }

    private var canRedirectToDiscoveryUI = true

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

    var authorizationParameters: OpenIdAuthorizationRequest.Parameters

    let viewController: UIViewController
    private let completion: AuthorizationCompletion

    init(viewController: UIViewController,
         authorizationParameters: OpenIdAuthorizationRequest.Parameters,
         completion: @escaping AuthorizationCompletion) {
        self.viewController = viewController
        self.authorizationParameters = authorizationParameters
        self.completion = completion
    }

    /// Updates the state to the requested value if possible. If the requested state is invalid
    /// it may update to a concluding state contining an error value in which case the request
    /// should error out.
    /// If the request has already entered a finished state, this function has no action.
    ///
    /// This method is not thread safe and it is up to the developer to ensure consistency in
    /// updates.
    func update(state newState: State) {
        // No state transition are valid after finshed is reached.
        guard !isFinished else {
            return
        }

        // If we've entered the concluding state, the only valid state is `.finished`
        guard !self.state.isConcludingState || newState.isFinishedState else {
            fatalError("The only valid transition from concluding state is to a finsihed state.")
        }

        switch newState {
        case .undefined, .discovery, .authorization, .concluding:
            // no special state managment required
            self.state = newState

        case .missingUserRecovery:
            // enusre we haven't redirected through ui before:
            guard !isAttemptingMissingUserRecovery else {
                let error = AuthorizationRequestError.tooManyRecoveries.asAuthorizationError
                self.state = .concluding(.error(error))
                return
            }

            // we're attemting to recover – permit redirects to discovery ui
            canRedirectToDiscoveryUI = true
            self.state = newState

        case .mobileNetworkSelection:
            // enusre we haven't redirected through ui before:
            guard canRedirectToDiscoveryUI else {
                let error = AuthorizationRequestError.tooManyRedirects.asAuthorizationError
                self.state = .concluding(.error(error))
                return
            }

            // only permit this re-direction one time:
            canRedirectToDiscoveryUI = false

            self.state = newState

        case .finished:
            // If we are moving to a finished state, establish we have previously entered a
            // concluding state and extract the outcome.
            guard case .concluding(let outcome) = self.state else {
                fatalError("You must transition to a concluding state before a finished state.")
            }
            // ensure consistency so update state before calling completion.
            self.state = newState
            // send the completion:
            completion(outcome)
        }
    }
}

private extension AuthorizationRequest.State {
    var isConcludingState: Bool {
        guard case .concluding = self else {
            return false
        }
        return true
    }

    var isFinishedState: Bool {
        guard case .finished = self else {
            return false
        }
        return true
    }
}

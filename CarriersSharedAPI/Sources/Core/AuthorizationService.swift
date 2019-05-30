//
//  AuthorizationService.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/19/19.
//  Copyright © 2018 XCI JV, LLC. ALL RIGHTS RESERVED.
//

import UIKit

/// Represents the successful compltion of an autorization request. The code should be used to
/// retrieve a token from a secure server.
public struct AuthorizedResponse: Equatable {
    /// Authorization code returned from the issuer.
    public let code: String
    /// The Mobile Country Code used to identify the correct issuer.
    public let mcc: String
    /// The Mobile Network Code used to identify the correct issuer.
    public let mnc: String
}

/// The outcome of an Authorization Operation.
public enum AuthorizationResult {
    /// A successful authorization returns the authorization code and mcc/mnc corresponding to the
    /// issuer used to return the authorized code.
    case code(AuthorizedResponse)
    /// When an error occurs it is surfaced here with this result.
    case error(AuthorizationError)
    /// When the authorization is cancelled this result is returned.
    case cancelled
}

public typealias AuthorizationCompletion = (AuthorizationResult) -> Void

/// The AuthorizationService interface.
protocol AuthorizationServiceProtocol {
    // swiftlint:disable function_parameter_count

    /// Requests authorization for the specified scopes from Project Verify.
    /// - Parameters:
    ///   - scopes: an array of scopes to be authorized for access. See the predefined
    ///     `Scope` for a list of supported scope types.
    ///   - viewController: the UI context from which the authorization request originated
    ///    this is used as the presentation view controller if additional ui is required for resolving
    ///    the request.
    ///   - acrValues: an array of authentication context class refernces. Service Providers may ask
    ///     for more than one, and will get the first one the user has achieved. Values returned in
    ///     id_token will contain aalx. Service Providers should not ask for any deprecated values
    ///     (loax). The default acrValue is aal1.
    ///   - state: an opaque value used to maintain state between the request and the callback. If
    ///     `nil` is passed, a random string will be used.
    ///   - correlationId: A string value or `nil`. Service Providers may send a tracking ID used
    ///     for transaction logging. SP’s will need to use the service portal for access to any
    ///     individual log entries. The default value is `nil`.
    ///   - context: A string value or `nil`. Service Providers will be able to submit
    ///     “text string” for authorization by the user. Best practice is a server-initiated request
    ///     should contain a context parameter, so that a user understands the reason for the
    ///     interaction.
    ///     Maximum size will be <280> characters. Any request with a context that is too large will
    ///     result in an OIDC error. (invalid request).
    ///     The default value is `nil`.
    ///   - prompt: a `PromptValue` or `nil`. If nil is passed the default behavior will be used.
    ///   - nonce: Any Service Provider specified string or `nil`. The string value is used to
    ///     associate a Client session with an ID Token, and to mitigate replay attacks. The value
    ///     is passed through unmodified from the Authentication Request to the ID Token. Sufficient
    ///     entropy MUST be present in the nonce values used to prevent attackers from guessing
    ///     values. If `nil` is passed, a random string will be used.
    ///   - completion: an escaping block executed asynchronously, on the main thread. This
    ///    block will take one parameter, a result, see `AuthorizationResult` for more information.
    ///
    /// - SeeAlso: ScopeProtocol
    /// - SeeAlso: Scopes
    /// - SeeAlso: AuthorizationResult
    func authorize(scopes: [ScopeProtocol],
                   fromViewController viewController: UIViewController,
                   acrValues: [ACRValue]?,
                   state: String?,
                   correlationId: String?,
                   context: String?,
                   prompt: PromptValue?,
                   nonce: String?,
                   completion: @escaping AuthorizationCompletion)

    // swiftlint:enable function_parameter_count
}

extension AuthorizationServiceProtocol {
    func authorize(
        scopes: [ScopeProtocol],
        fromViewController viewController: UIViewController,
        acrValues: [ACRValue]? = [.aal1],
        state: String? = nil,
        correlationId: String? = nil,
        context: String? = nil,
        prompt: PromptValue? = nil,
        nonce: String? = nil,
        completion: @escaping AuthorizationCompletion) {

        authorize(
            scopes: scopes,
            fromViewController: viewController,
            acrValues: acrValues,
            state: state,
            correlationId: correlationId,
            context: context,
            prompt: prompt,
            nonce: nonce,
            completion: completion
        )
    }
}

/// Authenticator Assurance Values.
///
/// For more informaiton see the [NIST guidelines](https://pages.nist.gov/800-63-3/sp800-63b.html)
public enum ACRValue: String {
    /// AAL1 provides some assurance that the claimant controls an authenticator bound to the
    /// subscriber’s account. AAL1 requires either single-factor or multi-factor authentication
    /// using a wide range of available authentication technologies. Successful authentication
    /// requires that the claimant prove possession and control of the authenticator through a
    /// secure authentication protocol.
    ///
    /// Service Providers should ask for aal1 when they need a low level of authentication, users
    /// will not be asked for their pin or biometrics. Any user holding the device will be able to
    /// authenticate/authorize the transaction unless the user has configured their account to
    /// always require 2nd factor (pin | bio).
    case aal1
    /// AAL2 provides high confidence that the claimant controls an authenticator(s) bound to the
    /// subscriber’s account. Proof of possession and control of two different authentication
    /// factors is required through secure authentication protocol(s). Approved cryptographic
    /// techniques are required at AAL2 and above.
    ///
    /// Service Providers should ask for aal2 or aal3 anytime they want to ensure the user has
    /// provided their (pin | bio).
    case aal2
    /// AAL3 provides very high confidence that the claimant controls authenticator(s) bound to the
    /// subscriber’s account. Authentication at AAL3 is based on proof of possession of a key
    /// through a cryptographic protocol. AAL3 authentication requires a hardware-based
    /// authenticator and an authenticator that provides verifier impersonation resistance;
    /// the same device may fulfill both these requirements. In order to authenticate at AAL3,
    /// claimants are required to prove possession and control of two distinct authentication
    /// factors through secure authentication protocol(s). Approved cryptographic techniques are
    /// required.
    ///
    /// Service Providers should ask for aal2 or aal3 anytime they want to ensure the user has
    /// provided their (pin | bio).
    case aal3
}

enum PromptValue: String {
    /// A Service Provider can ask for a user to authenticate again. (even if the user authenticated
    /// within the last sso authentication period (most carriers this will be 30 min).
    ///
    /// At this time every Service Provider request will trigger an authentication, so the use of
    /// this parameter is redundant.
    case login
    /// An SP can ask for a user to explicitly re-confirm that the user agrees to the exposure of
    /// their data. The MNO will recapture user consent for the listed scopes.
    case consent
}

/// An appropriate factory is registerd per-platform to vend the correct authorization service
/// when creating new instances.
protocol AuthorizationServiceFactory {
    func createAuthorizationService() -> AuthorizationServiceProtocol
}

/// This service provides an interface for authorizing an application with Project Verify.
public class AuthorizationService {
    let backingService: AuthorizationServiceProtocol

    public init() {
        let container: Dependencies = ProjectVerifyAppDelegate.shared.dependencies
        let factory: AuthorizationServiceFactory = container.resolve()
        self.backingService = factory.createAuthorizationService()
    }
}

extension AuthorizationService: AuthorizationServiceProtocol {
    // swiftlint:disable:next function_parameter_count
    func authorize(
        scopes: [ScopeProtocol],
        fromViewController viewController: UIViewController,
        acrValues: [ACRValue]?,
        state: String?,
        correlationId: String?,
        context: String?,
        prompt: PromptValue?,
        nonce: String?,
        completion: @escaping AuthorizationCompletion) {
        backingService.authorize(
            scopes: scopes,
            fromViewController: viewController,
            acrValues: acrValues,
            state: state,
            correlationId: correlationId,
            context: context,
            prompt: prompt,
            nonce: nonce,
            completion: completion
        )
    }
}

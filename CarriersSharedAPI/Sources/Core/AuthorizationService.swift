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

extension AuthorizationResult: CustomStringConvertible {
    public var description: String {
        let base = "AuthorizationResult:"
        switch self {
        case .code:
            return "\(base) auth code"
        case .error(let error):
            return "\(base) error: \(error.errorType)"
        case .cancelled:
            return "\(base) cancelled"
        }
    }
}

public typealias AuthorizationCompletion = (AuthorizationResult) -> Void

/// The AuthorizationService interface.
public protocol AuthorizationServiceProtocol: AnyObject {
    // swiftlint:disable function_parameter_count

    /// True if the authorization service is currently performing an authorization flow, else
    /// false.
    var isAuthorizing: Bool { get }

    /// Requests authorization for the specified scopes from Project Verify.
    /// - Parameters:
    ///   - scopes: An array of scopes to be authorized for access. See the predefined
    ///     `Scope` for a list of supported scope types.
    ///   - viewController: the UI context from which the authorization request originated
    ///    this is used as the presentation view controller if additional ui is required for resolving
    ///    the request.
    ///   - acrValues: An array of authentication context class refernces. Service Providers may ask
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
    ///   - prompt: A `PromptValue` or `nil`. If nil is passed the default behavior will be used.
    ///   - nonce: Any Service Provider specified string or `nil`. The string value is used to
    ///     associate a Client session with an ID Token, and to mitigate replay attacks. The value
    ///     is passed through unmodified from the Authentication Request to the ID Token. Sufficient
    ///     entropy MUST be present in the nonce values used to prevent attackers from guessing
    ///     values. The nonce is optional and the default value is `nil`. The
    ///     `RandomStringGenerator` class exposes a method suitable for generating this value.
    ///   - completion: an escaping block executed asynchronously, on the main thread. This
    ///    block will take one parameter, a result, see `AuthorizationResult` for more information.
    ///
    /// Your application should only ever make one authorization request at a time. To enusre a
    /// consistent user experience you should wait for the request to conclude or cancel any pending
    /// requests before starting another.
    /// You should only call this method from the main thread.
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

    /// Cancels the current authorization request, if any.
    ///
    /// You should only call this method from the main thread.
    func cancel()

    // swiftlint:enable function_parameter_count
}

public extension AuthorizationServiceProtocol {
    func authorize(
        scopes: [ScopeProtocol] = [Scope.openid],
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

// Combines these two protocols into one type
typealias AuthorizationServiceProtocolInternal = AuthorizationServiceProtocol & URLHandling

/// This service provides an interface for authorizing an application with Project Verify.
public class AuthorizationService {
    let backingService: AuthorizationServiceProtocolInternal

    public init() {
        let container: Dependencies = ProjectVerifyAppDelegate.shared.dependencies
        self.backingService = container.resolve()
    }
}

extension AuthorizationService: AuthorizationServiceProtocol {
    public var isAuthorizing: Bool {
        return backingService.isAuthorizing
    }

    // swiftlint:disable:next function_parameter_count
    public func authorize(
        scopes: [ScopeProtocol],
        fromViewController viewController: UIViewController,
        acrValues: [ACRValue]?,
        state: String?,
        correlationId: String?,
        context: String?,
        prompt: PromptValue?,
        nonce: String?,
        completion: @escaping AuthorizationCompletion) {

        if let previousRequest = AuthorizationServiceCurrentRequestStorage.shared.currentRequestingService {
            // if there is a previous request in flight, cancel it. There should only ever be one.
            previousRequest.cancel()
        }

        AuthorizationServiceCurrentRequestStorage.shared.currentRequestingService = backingService
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

    public func cancel() {
        backingService.cancel()
    }
}

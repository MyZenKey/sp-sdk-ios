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
    /// When the authorizaiton is cancelled this result is returned.
    case cancelled
}

public typealias AuthorizationCompletion = (AuthorizationResult) -> Void

/// The AuthorizationService interface.
protocol AuthorizationServiceProtocol {
    /// Requests authorization for the specified scopes from Project Verify.
    /// - Parameters:
    ///   - scopes: an array of scopes to be authorized for access. See the predefined
    ///     `Scope` for a list of supported scope types.
    ///   - viewController: the UI context from which the authorization request originated
    ///    this is used as the presentation view controller if additional ui is required for resolving
    ///    the request.
    ///   - completion: an escaping block executed asynchronously, on the main thread. This
    ///    block will take one parameter, a result, see `AuthorizationResult` for more information.
    ///
    /// - SeeAlso: ScopeProtocol
    /// - SeeAlso: Scopes
    /// - SeeAlso: AuthorizationResult
    func connectWithProjectVerify(
        scopes: [ScopeProtocol],
        fromViewController viewController: UIViewController,
        completion: @escaping AuthorizationCompletion)
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
    public func connectWithProjectVerify(
        scopes: [ScopeProtocol],
        fromViewController viewController: UIViewController,
        completion: @escaping AuthorizationCompletion) {

        backingService.connectWithProjectVerify(
            scopes: scopes,
            fromViewController: viewController,
            completion: completion
        )
    }
}

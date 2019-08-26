//
//  ProjectVerifyAuthorizeButton.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 4/3/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

/// Notifications for the ProjectVerifyAuthorizationButton authorization lifecycle
public protocol ProjectVerifyAuthorizeButtonDelegate: AnyObject {
    /// Called before the button starts the authorization request
    ///
    /// - Parameter button: the button implementing the request
    func buttonWillBeginAuthorizing(_ button: ProjectVerifyAuthorizeButton)

    /// Called upon request completion
    ///
    /// - Parameters:
    ///   - button: the button completing the request
    ///   - result: the result of the request
    /// - SeeAlso: `AuthorizationResult`
    func buttonDidFinish(
        _ button: ProjectVerifyAuthorizeButton,
        withResult result: AuthorizationResult)
}

/// A button which encapsulates the project verify authorization logic and exposes the outcomes
/// via a delegeate.
public final class ProjectVerifyAuthorizeButton: ProjectVerifyBrandedButton {

    /// A boolean indicating whether the backing autorization service is currently making a request
    ///
    /// - SeeAlso: `AuthorizationService`
    public var isAuthorizing: Bool {
        return authorizationService.isAuthorizing
    }

    /// The scopes the button will request when pressed. Assign this property before the button
    /// issues its request.
    ///
    /// - SeeAlso: ScopeProtocol
    /// - SeeAlso: Scopes
    public var scopes: [ScopeProtocol] = [] {
        didSet {
            updateButtonText()
        }
    }

    /// An array of authentication context class refernces. Service Providers may ask
    /// for more than one, and will get the first one the user has achieved. Values returned in
    /// id_token will contain aalx. Service Providers should not ask for any deprecated values
    /// (loax). The default acrValue is aal1.
    public var acrValues: [ACRValue]? = [.aal1]

    /// An opaque value used to maintain state between the request and the callback. If
    /// `nil` is passed, a random string will be used.
    /// Maximum size will be <280> characters. Any request with a context that is too large will
    /// result in an OIDC error. (invalid request).
    /// The default value is `nil`.
    public var requestState: String?

    /// A string value or `nil`. Service Providers may send a tracking ID used
    /// for transaction logging. SP’s will need to use the service portal for access to any
    /// individual log entries. The default value is `nil`.
    public var correlationId: String?

    /// A string value or `nil`. Service Providers will be able to submit
    /// “text string” for authorization by the user. Best practice is a server-initiated request
    /// should contain a context parameter, so that a user understands the reason for the
    /// interaction.
    public var context: String?

    /// A `PromptValue` or `nil`. If nil is passed the default behavior will be used.
    public var prompt: PromptValue?

    /// Any Service Provider specified string or `nil`. The string value is used to
    /// associate a Client session with an ID Token, and to mitigate replay attacks. The value
    /// is passed through unmodified from the Authentication Request to the ID Token. Sufficient
    /// entropy MUST be present in the nonce values used to prevent attackers from guessing
    /// values. The nonce is optional and the default value is `nil`. The
    /// `RandomStringGenerator` class exposes a method suitable for generating this value.
    public var nonce: String?

    /// the button's delegate
    /// - SeeAlso: ProjectVerifyAuthorizeButtonDelegate
    public weak var delegate: ProjectVerifyAuthorizeButtonDelegate?

    private var authorizationService: AuthorizationServiceProtocol
    private var controllerContextProvider: CurrentControllerContextProvider

    public override init() {
        self.authorizationService = AuthorizationService()
        self.controllerContextProvider = DefaultCurrentControllerContextProvider()
        super.init()
        configureButton()
    }

    init(authorizationService: AuthorizationServiceProtocol,
         controllerContextProvider: CurrentControllerContextProvider,
         brandingProvider: BrandingProvider) {
        self.authorizationService = authorizationService
        self.controllerContextProvider = controllerContextProvider
        super.init(brandingProvider: brandingProvider)
        configureButton()
    }

    public override init(frame: CGRect) {
        self.authorizationService = AuthorizationService()
        self.controllerContextProvider = DefaultCurrentControllerContextProvider()
        super.init(frame: frame)
        configureButton()
    }

    public required init?(coder aDecoder: NSCoder) {
        self.authorizationService = AuthorizationService()
        self.controllerContextProvider = DefaultCurrentControllerContextProvider()
        super.init(coder: aDecoder)
        configureButton()
    }

    /// Cancels the current authorization request, if any.
    public func cancel() {
        authorizationService.cancel()
    }

    @objc func handlePress(sender: Any) {

        if authorizationService.isAuthorizing {
            cancel()
        }

        guard let currentViewController = controllerContextProvider.currentController else {
            fatalError("attempting to authorize before the key window has a root view controller")
        }

        delegate?.buttonWillBeginAuthorizing(self)
        authorizationService.authorize(
            scopes: scopes,
            fromViewController: currentViewController,
            acrValues: acrValues,
            state: requestState,
            correlationId: correlationId,
            context: context,
            prompt: prompt,
            nonce: nonce) { [weak self] result in
                self?.handle(result: result)
        }
    }

    @objc func handleDidBecomeActive() {
        // This notificaiton will be recieved _after_ the redirect url is handled via. the main
        // queue. If the authorization service is still running, let's implicitly cancel the request
        // in favor of having the user retry the action.
        guard authorizationService.isAuthorizing else {
            return
        }
        authorizationService.cancel()
    }
}

private extension ProjectVerifyAuthorizeButton {
    func configureButton() {

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        configureSelectors()
        updateButtonText()
    }

    func configureSelectors() {
        addTarget(self, action: #selector(handlePress(sender:)), for: .touchUpInside)
    }

    func handle(result: AuthorizationResult) {
        delegate?.buttonDidFinish(self, withResult: result)
    }

    func updateButtonText() {
        let scopesSet = Set<String>(scopes.map { $0.scopeString })
        if  scopesSet.contains(Scope.authenticate.rawValue) ||
            scopesSet.contains(Scope.register.rawValue) {
            updateBrandedText(Localization.Buttons.signInWithProjectVerify)
        } else if scopesSet.contains(Scope.authorize.rawValue) ||
                  scopesSet.contains(Scope.secondFactor.rawValue) {
            updateBrandedText(Localization.Buttons.continueWithProjectVerify)
        } else {
            // use generic 'continue' message by default.
            updateBrandedText(Localization.Buttons.continueWithProjectVerify)
        }
    }
}

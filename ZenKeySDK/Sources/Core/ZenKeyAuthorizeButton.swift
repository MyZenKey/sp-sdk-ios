//
//  ZenKeyAuthorizeButton.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 4/3/19.
//  Copyright © 2019-2020 ZenKey, LLC.
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

/// Notifications for the ZenKeyAuthorizationButton authorization lifecycle
public protocol ZenKeyAuthorizeButtonDelegate: AnyObject {
    /// Called before the button starts the authorization request
    ///
    /// - Parameter button: the button implementing the request
    func buttonWillBeginAuthorizing(_ button: ZenKeyAuthorizeButton)

    /// Called upon request completion
    ///
    /// - Parameters:
    ///   - button: the button completing the request
    ///   - result: the result of the request
    /// - SeeAlso: `AuthorizationResult`
    func buttonDidFinish(
        _ button: ZenKeyAuthorizeButton,
        withResult result: AuthorizationResult)
}

/// A button which encapsulates the ZenKey authorization logic and exposes the outcomes
/// via a delegate.
public final class ZenKeyAuthorizeButton: ZenKeyBrandedButton {

    /// A boolean indicating whether the backing authorization service is currently making a request
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
    public var scopes: [ScopeProtocol] = []

    /// Allows the type of title to be set. "Sign in with ZenKey" is the default,
    /// and "Continue with ZenKey" is used if the titleType is set to .continue.
    public var titleType: TitleType = TitleType.signInWith {
        didSet {
            updateButtonText()
        }
    }

    /// An enum specifying which text appears on the button.
    public enum TitleType {
        case continueWith
        case signInWith
    }

    /// An array of authentication context class refernces. Service Providers may ask
    /// for more than one, and will get the first one the user has achieved. Values returned in
    /// id_token will contain aalx. Service Providers should not ask for any deprecated values
    /// (loax). The default acrValue is aal1.
    public var acrValues: [ACRValue]? = []

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

    /// Optional Theme (.light or .dark) to be used for the authorization UX. If included it will
    /// override user preference to ensure a coherent, consistent experience with the Service
    /// Provider's app design.
    public var theme: Theme?

    /// the button's delegate
    /// - SeeAlso: ZenKeyAuthorizeButtonDelegate
    public weak var delegate: ZenKeyAuthorizeButtonDelegate?

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

    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        configureButton()
    }

    /// Cancels the current authorization request, if any.
    public func cancel() {
        authorizationService.cancel()
    }

    @objc func handlePress(sender: Any) {

        guard isEnabled else { return }

        isEnabled = false

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
            nonce: nonce,
            theme: theme) { [weak self] result in
                self?.handle(result: result)
        }
    }

    @objc func handleDidBecomeActive() {
        // This notification will be recieved _after_ the redirect url is handled via the main
        // queue. If the authorization service is still running, let's implicitly cancel the request
        // in favor of having the user retry the action.
        guard authorizationService.isAuthorizing else {
            return
        }
        authorizationService.cancel()
    }
}

private extension ZenKeyAuthorizeButton {
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
        isEnabled = true
        delegate?.buttonDidFinish(self, withResult: result)
    }

    func updateButtonText() {
        switch titleType {
        case TitleType.continueWith:
            updateBrandedText(Localization.Buttons.continueWithZenKey)
        case TitleType.signInWith:
            updateBrandedText(Localization.Buttons.signInWithZenKey)
        }
    }
}

//
//  ZenKeyButtonView.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 4/3/19.
//  Copyright © 2019 XCI JV, LLC.
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

/// An enum specifying how carrier endorsement should be presented.
public enum EndorsementStyle {
    case none
    case carrierBelow
}

public class ZenKeyButtonView: UIView {
    /// Provide guidance for the button to use a light background button or a dark background button.
    public var style: ZenKeyBrandedButton.Style {
        get {
            return button.style
        }
        set(newStyle) {
            button.style = newStyle
        }
    }

    /// A boolean indicating whether the backing authorization service is currently making a request
    public var isAuthorizing: Bool {
        return button.isAuthorizing
    }

    /// The scopes the button will request when pressed. Assign this property before the button
    /// issues its request.
    ///
    /// - SeeAlso: ScopeProtocol
    /// - SeeAlso: Scopes
    public var scopes: [ScopeProtocol] {
        get {
            return button.scopes
        }
        set(newScopes) {
            button.scopes = newScopes
        }
    }

    /// Allows the type of title to be set. "Sign in with ZenKey" is the default,
    /// and "Continue with ZenKey" is used if the titleType is set to .continue.
    public var titleType: ZenKeyAuthorizeButton.TitleType {
        get {
            return button.titleType
        }
        set(newType) {
            button.titleType = newType
        }
    }

    /// An array of authentication context class refernces. Service Providers may ask
    /// for more than one, and will get the first one the user has achieved. Values returned in
    /// id_token will contain aalx. Service Providers should not ask for any deprecated values
    /// (loax). The default acrValue is aal1.
    public var acrValues: [ACRValue]? {
        get {
            return button.acrValues
        }
        set(newValues) {
            button.acrValues = newValues
        }
    }

    /// An opaque value used to maintain state between the request and the callback. If
    /// `nil` is passed, a random string will be used.
    /// Maximum size will be <280> characters. Any request with a context that is too large will
    /// result in an OIDC error. (invalid request).
    /// The default value is `nil`.
    public var requestState: String? {
        get {
            return button.requestState
        }
        set(newState) {
            button.requestState = newState
        }
    }

    /// A string value or `nil`. Service Providers may send a tracking ID used
    /// for transaction logging. SP’s will need to use the service portal for access to any
    /// individual log entries. The default value is `nil`.
    public var correlationId: String? {
        get {
            return button.correlationId
        }
        set(newCorrelationId) {
            button.correlationId = newCorrelationId
        }
    }

    /// A string value or `nil`. Service Providers will be able to submit
    /// “text string” for authorization by the user. Best practice is a server-initiated request
    /// should contain a context parameter, so that a user understands the reason for the
    /// interaction.
    public var context: String? {
        get {
            return button.context
        }
        set(newContext) {
            button.context = newContext
        }
    }

    /// A `PromptValue` or `nil`. If nil is passed the default behavior will be used.
    public var prompt: PromptValue? {
        get {
            return button.prompt
        }
        set(newPrompt) {
            button.prompt = newPrompt
        }
    }

    /// Any Service Provider specified string or `nil`. The string value is used to
    /// associate a Client session with an ID Token, and to mitigate replay attacks. The value
    /// is passed through unmodified from the Authentication Request to the ID Token. Sufficient
    /// entropy MUST be present in the nonce values used to prevent attackers from guessing
    /// values. The nonce is optional and the default value is `nil`. The
    /// `RandomStringGenerator` class exposes a method suitable for generating this value.
    public var nonce: String? {
        get {
            return button.nonce
        }
        set(newNonce) {
            button.nonce = newNonce
        }
    }

    /// Enabled state of enclosed button
    public var isEnabled: Bool {
        get {
            return button.isEnabled
        }
        set(newState) {
            button.isEnabled = newState
        }
    }

    /// the button's delegate
    public var delegate: ZenKeyAuthorizeButtonDelegate? {
        get {
            return button.delegate
        }
        set(newDelegate) {
            button.delegate = newDelegate
        }
    }

    private lazy var button: ZenKeyAuthorizeButton = {
        let button = ZenKeyAuthorizeButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.brandingDelegate = self
        return button
    }()

    private let poweredByLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    public init(with endorsementStyle: EndorsementStyle = .none) {
        super.init(frame: .zero)
        layoutContent(with: endorsementStyle)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func cancel() {
        button.cancel()
    }
}

private extension ZenKeyButtonView {
    /// View should never resize once initialized.
    func layoutContent(with endorsementStyle: EndorsementStyle) {
        addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),

        ])
        switch endorsementStyle {
        case .none:
            button.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        case .carrierBelow:
            addSubview(poweredByLabel)
            NSLayoutConstraint.activate([
                button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50.0),
                poweredByLabel.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 16.0),
                poweredByLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            ])
        }
    }
}

extension ZenKeyButtonView: ZenKeyBrandedButtonDelegate {
    public func brandingWillUpdate(_ oldBranding: Branding, forButton button: ZenKeyBrandedButton) { }

    public func brandingDidUpdate(_ newBranding: Branding, forButton button: ZenKeyBrandedButton) {
        let color: UIColor = (style == .dark) ? .black : .white
        if newBranding.carrierIcon != nil {
            //TODO: Show carrier logo design
        } else {
            guard let carrierText = newBranding.carrierText,
                !carrierText.isEmpty else {
                return
            }

            poweredByLabel.attributedText = Fonts.mediumAccessoryText(
                text: carrierText,
                withColor: color
            )
        }
        poweredByLabel.isHidden = false
    }
}

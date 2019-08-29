//
//  Scopes.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/26/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

/// The protocol any type must conform to to represent a scope request.
public protocol ScopeProtocol {
    /// The string which will represent the scope over the network.
    var scopeString: String { get }
}

/// The predefined scopes supported by ZenKey.
public enum Scope: String, ScopeProtocol, Equatable {
    /// This scope will return an ID_token from the Token endpoint. Future updates may include
    /// additional data claims in the ID_token.  Note: even the access token is a JWT.
    case openid

    /// The user's name
    ///
    /// This is a data scope. It will enable a Service Provider to access data from the userinfo
    /// (or other endpoints). See the user info documentation to see example data exposed with each
    /// scope.
    case name

    /// The user's birthdate
    ///
    /// This is a data scope. It will enable a Service Provider to access data from the userinfo
    /// (or other endpoints). See the user info documentation to see example data exposed with each
    /// scope.
    case birthdate

    /// If the user is 18 years or older when known
    ///
    /// This is a data scope. It will enable a Service Provider to access data from the userinfo
    /// (or other endpoints). See the user info documentation to see example data exposed with each
    /// scope.
    case isAdult = "is_adult"

    /// A url for a profile picture.
    ///
    /// This is a data scope. It will enable a Service Provider to access data from the userinfo
    /// (or other endpoints). See the user info documentation to see example data exposed with each
    /// scope.
    case picture

    /// User email
    case email

    /// User address
    case address

    /// User phone
    case phone

    /// User postal code
    case postalCode = "postal_code"

    /// Service providers may request a user's current location
    case location

    /// A service provider may request access to a user’s security events. When a service provider
    /// has a registered event_uri, and the user has consented to this service provider having access to the
    /// events scope. Then the service provider may receive Security event tokens.
    case events

    /// This is a required scope to get a refresh token. service providerss are encouraged to use
    /// server-initiated flows instead of refresh tokens.
    case offlineAccess = "offline_access"

    /// A service provider may request users' permission to access risk scores. The various different
    /// scores may all be received once the service provider has this scope consented. Requests will
    /// be directed to the IDV engine for these requests.
    case score

    //// An service provider may ask to verify users data. After securing the consent the RP may
    /// submit attributes to the IDV engine to receive a match response
    case match

    /// Indicates an authorization flow request
    /// When the authorize scope is present the user will be stopped to confirm the transaction
    /// (even if the scopes have been approved before)
    ///
    /// - Note: Service providers can set authorize, authenticate, register, 2ndfactor, scopes. These will
    /// be present in logs, and will enable tracking of the desired user experience. These may be
    /// used to tune the user experience such as screen and button labels. The presence of these
    /// scopes in a request will NOT impact the information the user provides to the service provider
    case authorize

    /// Indicates a registration flow request
    ///
    /// - Note: Service providers can set authorize, authenticate, register, 2ndfactor, scopes. These will
    /// be present in logs, and will enable tracking of the desired user experience. These may be
    /// used to tune the user experience such as screen and button labels. The presence of these
    /// scopes in a request will NOT impact the information the user provides to the service provider
    case register

    /// Indicates a multifactor flow request
    ///
    /// - Note: Service providers can set authorize, authenticate, register, 2ndfactor, scopes. These will
    /// be present in logs, and will enable tracking of the desired user experience. These may be
    /// used to tune the user experience such as screen and button labels. The presence of these
    /// scopes in a request will NOT impact the information the user provides to the service provider
    case secondFactor = "2ndfactor"

    /// Inicates an authentication request
    ///
    /// When `.authenticate` is present, the user will be stopped to confirm the transaction.
    /// Authenticate may cancel any open sso sessions if the user fails to authenticate this
    /// service provider.
    /// Service providers may use the `.authenticate` and `.authorize` scopes at the same time
    /// - Note: Service providers can set authorize, authenticate, register, 2ndfactor, scopes. These will
    /// be present in logs, and will enable tracking of the desired user experience. These may be
    /// used to tune the user experience such as screen and button labels. The presence of these
    /// scopes in a request will NOT impact the information the user provides to the service provider
    case authenticate

    public var scopeString: String {
        return self.rawValue
    }
}

struct OpenIdScopes {
    var networkFormattedString: String {
        return requestedScopes.toOpenIdScopes
    }
    let requestedScopes: [ScopeProtocol]
    init(requestedScopes: [ScopeProtocol]) {
        self.requestedScopes = requestedScopes
    }
}

extension Array where Element == ScopeProtocol {
    var toOpenIdScopes: String {
        return self.map({ $0.scopeString })
            .deduplicateStrings
            .sorted()
            .joined(separator: " ")
    }
}

extension Array where Element == String {
    var deduplicateStrings: [String] {
        return [String](Set<String>(self))
    }
}

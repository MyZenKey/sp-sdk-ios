//
//  Scopes.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/26/19.
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

    /// User email
    case email

    /// User phone
    case phone

    /// User postal code
    case postalCode = "postal_code"

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

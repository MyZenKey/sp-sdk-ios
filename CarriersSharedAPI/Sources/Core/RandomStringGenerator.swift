//
//  RandomStringGenerator.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 5/31/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
import AppAuth

/// A string generator that returns cryptographically secure random strings suitable for different
/// uses.
public struct RandomStringGenerator {
    /// @returns a string suitable for the authorization state parameter or nil if the system is
    ///     unable to generate a secure random string.
    public static func generateStateSuitableString() -> String? {
        return OIDAuthorizationRequest.generateState()
    }

    /// @returns a string suitable for the authorization nonce parameter or nil if the system is
    ///     unable to generate a secure random string.
    public static func generateNonceSuitableString() -> String? {
        return OIDAuthorizationRequest.generateState()
    }
}

enum RequestStateError: Error {
    case generationFailed
}

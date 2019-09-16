//
//  RandomStringGenerator.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 5/31/19.
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

/// A string generator that returns cryptographically secure random strings suitable for different
/// uses.
public struct RandomStringGenerator {
    /// Generate a random string suitable for use as the state parameter.
    ///
    /// - Returns: a string suitable for the authorization state parameter or nil if the system is
    /// unable to generate a secure random string.
    public static func generateStateSuitableString() -> String? {
        return cryptographicallySecureRandomString(byteLength: 32)
    }

    /// Generate a random string suitable for use as the nonce parameter.
    ///
    /// - Returns: a string suitable for the authorization nonce parameter or nil if the system is
    /// unable to generate a secure random string.
    public static func generateNonceSuitableString() -> String? {
        return cryptographicallySecureRandomString(byteLength: 32)
    }
}

enum RequestStateError: Error {
    case generationFailed
}

private extension RandomStringGenerator {
    static func cryptographicallySecureRandomString(byteLength len: Int) -> String? {
        var bytes = [UInt8](repeating: 0, count: len)
        let statusCode = SecRandomCopyBytes(kSecRandomDefault, len, &bytes)
        guard statusCode == errSecSuccess else {
            return nil
        }

        return Data(bytes: &bytes, count: len)
            .base64URLEncodedString()
    }
}

private extension Data {
    /// base64url encoded string per [rfc 4649 sec. 5](https://www.ietf.org/rfc/rfc4648.txt)
    ///
    /// omits padding and substitutes the 62nd and 63rd character for url safe variants.
    func base64URLEncodedString() -> String {
        return self
            .base64EncodedString(options: .lineLength64Characters)
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
}

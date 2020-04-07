//
//  OpenIdAuthorizationRequest.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 7/26/19.
//  Copyright © 2019 ZenKey, LLC.
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

import CommonCrypto
#if canImport(CryptoKit)
    import CryptoKit
#endif

enum ResponseType: String {
    case code
}

struct OpenIdAuthorizationRequest: Equatable {
    let resource: URL
    let parameters: Parameters
    let pkce: ProofKeyForCodeExchange

    init(resource: URL, parameters: Parameters) {
        self.resource = resource
        self.parameters = parameters
        self.pkce = ProofKeyForCodeExchange()
    }

}

extension OpenIdAuthorizationRequest {
    struct Parameters: Equatable {
        let clientId: String
        let redirectURL: URL
        let formattedScopes: String
        private(set) var state: String?
        let nonce: String?

        let acrValues: [ACRValue]?
        let prompt: PromptValue?
        let correlationId: String?
        let context: String?
        var loginHintToken: String?
        let version: String
        let theme: Theme?

        init(clientId: String,
             redirectURL: URL,
             formattedScopes: String,
             state: String?,
             nonce: String?,
             acrValues: [ACRValue]?,
             prompt: PromptValue?,
             correlationId: String?,
             context: String?,
             loginHintToken: String?,
             theme: Theme?) {

            self.clientId = clientId
            self.redirectURL = redirectURL
            self.formattedScopes = formattedScopes
            self.state = state
            self.nonce = nonce
            self.acrValues = acrValues
            self.prompt = prompt
            self.correlationId = correlationId
            self.context = context
            self.loginHintToken = loginHintToken
            self.version = VERSION
            self.theme = theme
        }

        mutating func safeSet(state: String) {
            guard self.state == nil else {
                Log.log(.warn, "Attempting to set login hint token when it was already set.")
                return
            }
            self.state = state
        }

    }
}

extension OpenIdAuthorizationRequest {
    enum Keys: String {
        case clientId = "client_id"
        case scope
        case redirectURI = "redirect_uri"
        case responesType = "response_type"
        case state
        case nonce

        // additonal params:
        case loginHintToken = "login_hint_token"
        case acrValues = "acr_values"
        case correlationId = "correlation_id"
        case context = "context"
        case prompt = "prompt"
        case codeChallenge = "code_challenge"
        case codeChallengeMethod = "code_challenge_method"
        case version = "sdk_version"
        case options = "options"
    }

    var authorizationRequestURL: URL {
        let params: [URLQueryItem] = [
            URLQueryItem(name: Keys.clientId.rawValue, value: parameters.clientId),
            URLQueryItem(name: Keys.scope.rawValue, value: parameters.formattedScopes),
            URLQueryItem(name: Keys.redirectURI.rawValue, value: parameters.redirectURL.absoluteString),
            URLQueryItem(name: Keys.responesType.rawValue, value: ResponseType.code.rawValue),
            URLQueryItem(name: Keys.state.rawValue, value: parameters.state),
            URLQueryItem(name: Keys.nonce.rawValue, value: parameters.nonce),

            URLQueryItem(name: Keys.loginHintToken.rawValue, value: parameters.loginHintToken),
            URLQueryItem(name: Keys.acrValues.rawValue, value: parameters.acrValues?
                .map() { $0.rawValue }
                .joined(separator: " ")),
            URLQueryItem(name: Keys.correlationId.rawValue, value: parameters.correlationId),
            URLQueryItem(name: Keys.context.rawValue, value: parameters.context),
            URLQueryItem(name: Keys.prompt.rawValue, value: parameters.prompt?.rawValue),
            URLQueryItem(name: Keys.codeChallenge.rawValue, value: pkce.codeChallenge),
            URLQueryItem(name: Keys.codeChallengeMethod.rawValue, value: pkce.codeChallengeMethod.rawValue),
            URLQueryItem(name: Keys.version.rawValue, value: VERSION),
            URLQueryItem(name: Keys.options.rawValue, value: parameters.theme?.rawValue),
        ].filter() { $0.value != nil }

        var builder = URLComponents(url: resource, resolvingAgainstBaseURL: false)
        builder?.queryItems = params

        guard
            let components = builder,
            let url = components.url
            else {
                fatalError("unable to assemble correct url for auth request \(self)")
        }

        return url
    }
}

enum CodeChallengeMethod: String {
    case s256 = "S256"
    case plain
}

struct ProofKeyForCodeExchange: Equatable {
    let codeVerifier: String
    let codeChallenge: String
    let codeChallengeMethod: CodeChallengeMethod

    /// Generate random codeVerifier string and build codeChallenge hash
    init() {
        codeVerifier = Self.generateCodeVerifier()
        let challenge = Self.generateCodeChallenge(codeVerifier: codeVerifier)

        if challenge == codeVerifier {
            codeChallengeMethod = .plain
            // encode with base64url if we can't use SHA256
            codeChallenge = codeVerifier
        } else {
            codeChallengeMethod = .s256
            codeChallenge = challenge
        }
    }

    // Returns code challenge generated from random codeVerifier string.
    // If challenge cannot be generated, codeVerifier is returned.
    static func generateCodeChallenge(codeVerifier: String) -> String {

        // Encoding should never fail for utf8, but other encodings may return nil if
        // the reciever cannot be converted without losing some information. For example,
        // converting NSUnicodeStringEncoding to NSASCIIStringEncoding, the character 'Á' becomes 'A'.
        guard let codeData = codeVerifier.data(using: .utf8) else {
            Log.log(.error, "Failed to render utf8 codeVerifier")
            return codeVerifier
        }
        var shaByteArray: [UInt8]

        // work around compiler/linker issues by checking twice. Archive fails if only test #available
        if #available(iOS 13.0, *) {
            #if canImport(CryptoKit)
                // Use CryptoKit
                let shaDigest = SHA256.hash(data: codeData)
                shaByteArray = Array(shaDigest.makeIterator())
            #else
                fatalError("iOS 13 is missing CryptoKit")
            #endif
        } else {
            // Use CommonCrypto if iOS13 not available
            shaByteArray = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            codeData.withUnsafeBytes { (buffer) -> Void in
                CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &shaByteArray)
            }
        }
        let base64sha = Data(bytes: shaByteArray as [UInt8], count: shaByteArray.count).base64URLString()
        return base64sha
    }

    // Generate codeVerifier, a random string of length 128 from chars in `validChars`.
    static func generateCodeVerifier() -> String {
        // Generate codeVerifier:
        let validChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        let codeVerifier = String((0..<128).map { _ in validChars.randomElement()! })
        return codeVerifier
    }
}

extension Data {
    // Returns string encoded with base64url encoding as per RFC-4648 [https://tools.ietf.org/html/rfc4648]
    // Replaces '+' and '/' with '-' and '_' respectively.
    // Padding is omitted.

    func base64URLString(noWrap: Bool = true) -> String {
        var encodedOptions: Data.Base64EncodingOptions = []
        if noWrap == false {
            encodedOptions = .lineLength64Characters
        }
        var encodedContext = self.base64EncodedString(options: encodedOptions)
        encodedContext = encodedContext.replacingOccurrences(of: "=", with: "")
        encodedContext = encodedContext.replacingOccurrences(of: "+", with: "-")
        encodedContext = encodedContext.replacingOccurrences(of: "/", with: "_")
        return encodedContext
    }
}

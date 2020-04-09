//
//  Constants.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/25/19.
//  Copyright © 2019 ZenKey, LLC. All rights reserved.
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

import XCTest
@testable import ZenKeySDK

let timeout: TimeInterval = 10.0

struct UnexpectedNilVariableError: Error {}

// swiftlint:disable:next identifier_name
func UnwrapAndAssertNotNil<T>(_ variable: T?,
                              message: String = "Unexpected nil variable",
                              file: StaticString = #file,
                              line: UInt = #line) throws -> T {

    guard let variable = variable else {
        XCTFail(message, file: file, line: line)
        throw UnexpectedNilVariableError()
    }
    return variable
}

// swiftlint:disable:next identifier_name
func AssertHasQueryItemPair(url: URL?, key: String, value: String, file: StaticString = #file, line: UInt = #line) {
    guard
        let existingURL = url,
        let components = URLComponents(url: existingURL, resolvingAgainstBaseURL: false),
        let queryItems = components.queryItems,
        queryItems.contains(URLQueryItem(name: key, value: value)) else {
            XCTFail("expected valid url with valid query pair. instead got: \(url.debugDescription)",
                file: file,
                line: line)
            return
    }
}

// swiftlint:disable:next identifier_name
func AssertDoesntContainQueryItem(url: URL?, key: String) {
    guard
        let existingURL = url,
        let components = URLComponents(url: existingURL, resolvingAgainstBaseURL: false),
        let queryItems = components.queryItems,
        !queryItems.contains(where: { item in item.name == key }) else {
            XCTFail("expected valid url without the query param. instead got: \(url.debugDescription)")
            return
    }
}

struct MockSIMs {
    static let unknown = SIMInfo(mcc: "123", mnc: "456")
    static let tmobile = SIMInfo(mcc: "310", mnc: "210")
    static let att = SIMInfo(mcc: "310", mnc: "410")
}

extension URL {
    static var mocked: URL {
        return URL(string: "https://myzenkey.com")!
    }
}

extension NSError {
    static var mocked: NSError {
        return NSError(domain: "mockerror", code: 0, userInfo: [:])
    }
}

extension AuthorizationError {
    static var mocked: AuthorizationError {
        return AuthorizationError(rawErrorCode: "mock_error", description: "a mock error")
    }
}

extension OpenIdConfig {
    static var mocked: OpenIdConfig {
        return OpenIdConfig(authorizationEndpoint: URL.mocked,
                            issuer: URL.mocked)
    }
}

extension OpenIdAuthorizationRequest.Parameters {
    static var mocked: OpenIdAuthorizationRequest.Parameters {
        return OpenIdAuthorizationRequest.Parameters(
            clientId: "mockClientId",
            redirectURL: URL.mocked,
            formattedScopes: "openid authorization",
            state: "foo",
            nonce: "bar",
            acrValues: nil,
            prompt: nil,
            correlationId: nil,
            context: nil,
            loginHintToken: nil,
            theme: nil
        )
    }
}

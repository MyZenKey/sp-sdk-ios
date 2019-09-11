//
//  ServiceProviderAPIProtocol.swift
//  BankApp
//
//  Created by Adam Tierney on 8/27/19.
//  Copyright © 2018 XCI JV, LLC. ALL RIGHTS RESERVED.
//

import Foundation

struct AuthPayload {
    let token: String
}

struct UserInfo {
    let username: String
    let email: String?
    let name: String?
    let givenName: String?
    let familyName: String?
    let birthdate: String?
    let postalCode: String?
}

struct Transaction: Codable {
    let time: Date
    let recipiant: String
    let amount: String

    func contextString() -> String {
        return "Confirm you would like to transfer \(amount) to \(recipiant)."
    }
}

enum TransactionError: Error {
    case unableToParseToken
    case mismatchedTransaction
}

enum LoginError: Error {
    case invalidCredentials
}

enum ServiceError: Error {
    case invalidToken
    case unknownError
}

extension HTTPURLResponse {
    var errorValue: Error? {
        switch statusCode {
        case 401:
            return ServiceError.invalidToken
        case 402...599:
            return ServiceError.unknownError
        default:
            return nil
        }
    }
}

/// This interface describes what an abstraction of the layer between your client and your server
/// might look like. Each of these functions describe how that conversation might be supported
/// by ZenKey.
protocol ServiceProviderAPIProtocol {

    /// Authenticate a user without ZenKey, this represents what your sign in flow might look
    /// currently – driven by a traditional username and password authentication.
    ///
    /// - Parameters:
    ///   - username: The user's username for your application.
    ///   - password: The user's password for your application.
    ///   - completion:  An async callback with the result of the login request.
    func login(
        withUsername username: String,
        password: String,
        completion: @escaping (AuthPayload?, Error?) -> Void)

    /// Authenticate a user with ZenKey using the authorization code from a successful
    /// authorization by a ZenKey user. Each of these fields (with the exception of
    /// completion are returned from the `authorize(...)` request the SDK performs.
    ///
    /// With the auth code, mcc, and mnc, you have everything you need to re-perform discovery
    /// on your secure server and use the discovered token endpoint to request an access token
    /// from ZenKey. This access token shouldn't reach the client transparently,
    /// but instead be used as the basis for accessing or creating a token within
    /// the domain of your application.
    ///
    /// - Parameters:
    ///   - code: The authorization code.
    ///   - redirectURI: The redirect URI used to produce this code.
    ///   - mcc: The mobile country code value (used to perform discovery on the server).
    ///   - mnc: The mobile network code value (used to perform discovery on the server).
    ///   - completion: An async callback with the result of the login request.
    func login(
        withAuthCode code: String,
        redirectURI: URL,
        mcc: String,
        mnc: String,
        completion: @escaping (AuthPayload?, Error?) -> Void)

    /// Attach a completed ZenKey authorization flow to an existing user. This represents
    /// the second factor use case where ZenKey provides the user with a second form of
    /// consent to ensure they originate the login action.
    ///
    /// Your server is responsible for performing the token request as you would when using ZenKey
    /// as the primary means of authentication. The successfully returned token request
    /// validates that the user has approved the second factor request. You can store the user's sub
    /// value and compare it against future requests to ensure the correct user is approving the
    /// action.
    ///
    /// - Parameters:
    ///   - code: The authorization code.
    ///   - redirectURI: The redirect URI used to produce this code.
    ///   - mcc: The mobile country code value (used to perform discovery on the server).
    ///   - mnc: The mobile network code value (used to perform discovery on the server).
    ///   - completion: An async callback with the result of the request.
    func addSecondFactor(
        withAuthCode code: String,
        redirectURI: URL,
        mcc: String,
        mnc: String,
        completion: @escaping (AuthPayload?, Error?) -> Void)

    /// Request the user's info from your server.
    ///
    /// Once you've successfully exchanged the authorization code for an authorization token
    /// on your secure server, you'll be able to access the ZenKey User Info Endpoint.
    /// The ZenKey User Info Endpoint shouldn't be accessed from a client but instead
    /// should pass information through your server's authenticated endpoints in a way that
    /// makes sense for your application. The user info endpoint will reflect the information your
    /// user has approved scopes for.
    ///
    /// - Parameter completion: An async callback with the result of the request.
    func getUserInfo(completion: @escaping (UserInfo?, Error?) -> Void)

    /// Approve some action with ZenKey for which you've requested the `authorize` scope and
    /// an appropriate context string.
    ///
    /// Your server is responsible for performing the token request as you would when using ZenKey
    /// to authenticate. The successful token request will return a value containing a JWT
    /// for the field id_token. You should introspect this token to verify that the nonce value and
    /// context string are the same as those requested from the user via ZenKey. This
    /// ensures the integrity of the request and consent from the user.
    ///
    /// - Parameters:
    ///   - code: The authorization code.
    ///   - redirectURI: The redirect URI used to produce this code.
    ///   - transaction: The transaction you've requested. Its contextString should be compared with the context
    ///     value returned in the id_token from the token endpoint to ensure integrity.
    ///   - nonce: The nonce value you passed. It should be compared with the nonce value returned
    ///     in the id_token from the token endpoint to ensure integrity.
    ///   - completion: An async callback with the result of the request.
    func requestTransfer(withAuthCode code: String,
                         redirectURI: URL,
                         transaction: Transaction,
                         nonce: String,
                         completion: @escaping (Transaction?, Error?) -> Void)

    /// End the user's current session
    ///
    /// - Parameter completion: An async callback with the result of the request.
    func logout(completion: @escaping (Error?) -> Void)
}

extension ServiceProviderAPIProtocol {
    static func log(_ str: String) {
        print("|ServiceProviderAPI| \(str)")
    }

    static func log(request urlRequest: URLRequest) {
        guard
            let url = urlRequest.url,
            let method = urlRequest.httpMethod else {
                log("invalid request: \(urlRequest)")
                return
        }

        log("requesting: \(urlRequest)")
        print("curl -v -X \(method) \\")
        urlRequest.allHTTPHeaderFields?.forEach() { key, value in
            print("-H '\(key): \(value)' \\")
        }

        if let httpBody = urlRequest.httpBody, let bodyString = String(data: httpBody, encoding: .utf8) {
            print("-d \"\(bodyString)\" \\")
        }

        print("\"\(url.absoluteString)\"")
    }
}

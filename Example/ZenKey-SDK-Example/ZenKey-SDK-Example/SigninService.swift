//
//  SignInService.swift
//  ZenKeySDK
//
//  Created by Sawyer Billings on 2/18/20.
//  Copyright © 2020 ZenKey, LLC.
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
import ZenKeySDK
import os

protocol SignInProtocol {

    func signIn(authResponse: AuthorizedResponse, completion: @escaping (Result<SignInResponse, SignInError>) -> Void)

    func signOut(completion: @escaping (Result<Void, SignOutError>) -> Void)

    func getUser(completion: @escaping (Result<User, UserResponseError>) -> Void)

}

class SignInService: SignInProtocol {
    // A default API key in Info.plist has been matched to the ZenKey backend sample code,
    // but it can be replaced with a custom value.
    private let apiKey: String = {
        guard let apiKey = Bundle.main.infoDictionary?["APIKey"] as? String else {
            fatalError("missing API Key")
        }
        return apiKey
    }()

    var apiToken: String?

    lazy var session = URLSession(configuration: URLSessionConfiguration.default)

    var baseURL: URL = {
        guard let string = Bundle.main.infoDictionary?["baseURL"] as? String, let url = URL(string: string) else {
            fatalError("You must assign your baseURL in Info.plist")
        }
        return url
    }()

    var clientId: String = {
        // only used to check for correct project set-up
        guard let string = Bundle.main.infoDictionary?["ZenKeyClientId"] as? String, string != "<your-client-id>" else {
            fatalError("You must assign your ZenKeyClientId in Info.plist")
        }
        return string
    }()

    enum HTTPMethod {
        static var delete = "DELETE"
        static var post = "POST"
        static var get = "GET"
    }

}

extension SignInService {
    ///
    /// Sign user into the app using data from the ZenKey authorization response
    ///
    /// - Parameters:
    ///   - authResponse: The ZenKeySDK authorization response
    ///   - completion: An async callback with the result of the sign in request.
    ///
    func signIn(authResponse: AuthorizedResponse, completion: @escaping (Result<SignInResponse, SignInError>) -> Void) {
        var request = URLRequest(url: baseURL.appendingPathComponent("auth/zenkey-signin"))
        setHeader(for: &request)
        // Add parameters to request
        do {
            // AuthorizedResponse is Encodable for your convenience.
            // CodingKeys match those used in the carrier token request/response on your backend.
            let jsonData = try JSONEncoder().encode(authResponse)
            request.httpMethod = HTTPMethod.post
            request.httpBody = jsonData
        } catch let jsonError {
            os_log("Failed to encode AuthorizedResponse %@", jsonError.localizedDescription)
            completion(.failure(.jsonError(jsonError)))
            return
        }
        logRequest(request)

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.sessionError(error)))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                completion(.failure(.malformedResponse))
                return
            }
            self.logResponseData(data)

            // Parse response
            do {
                let snakeDecoder = JSONDecoder()
                snakeDecoder.keyDecodingStrategy = .convertFromSnakeCase
                switch httpResponse.statusCode {
                case 200:
                    // success
                    let signInResponse = try snakeDecoder.decode(SignInResponse.self, from: data)

                    // persist session token in the service layer.
                    self.apiToken = "Bearer " + signInResponse.token

                    completion(.success(signInResponse))
                case 403:
                    // un-linked user
                    let unlinkedResponse = try snakeDecoder.decode(UnlinkedResponse.self, from: data)
                    completion(.failure(.unlinkedUser(unlinkedResponse)))
                case 400:
                    let errorResponse = try snakeDecoder.decode(ErrorResponse.self, from: data)
                    completion(.failure(.badRequest(errorResponse.errorDescription)))
                case 401:
                    let errorResponse = try snakeDecoder.decode(ErrorResponse.self, from: data)
                    completion(.failure(.unauthorized(errorResponse.errorDescription)))
                case 500:
                    let errorResponse = try snakeDecoder.decode(ErrorResponse.self, from: data)
                    completion(.failure(.internalServerError(errorResponse.errorDescription)))
                default:
                    let errorResponse = try snakeDecoder.decode(ErrorResponse.self, from: data)
                    completion(.failure(.serverError(errorResponse.errorDescription)))
                }
            } catch let jsonError {
                os_log("Failed to decode SignInResponse %@", jsonError.localizedDescription)
                completion(.failure(.jsonError(jsonError)))
            }
            return
        }
        task.resume()
    }

    ///
    /// Sign user out of the example app
    ///
    func signOut(completion: @escaping (Result<Void, SignOutError>) -> Void) {
        var request = URLRequest(url: baseURL.appendingPathComponent("/auth/token"))
        request.httpMethod = HTTPMethod.delete
        setHeader(for: &request)
        logRequest(request)

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.sessionError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                completion(.failure(.malformedResponse))
                return
            }
            self.logResponseData(data)

            // Parse response
            do {
                let snakeDecoder = JSONDecoder()
                snakeDecoder.keyDecodingStrategy = .convertFromSnakeCase
                switch httpResponse.statusCode {
                case 200:
                    // success
                    self.apiToken = nil
                    completion(.success(()))
                case 401:
                    let errorResponse = try snakeDecoder.decode(ErrorResponse.self, from: data)
                    completion(.failure(.unauthorized(errorResponse.errorDescription)))
                case 500:
                    let errorResponse = try snakeDecoder.decode(ErrorResponse.self, from: data)
                    completion(.failure(.internalServerError(errorResponse.errorDescription)))
                default:
                    let errorResponse = try snakeDecoder.decode(ErrorResponse.self, from: data)
                    completion(.failure(.serverError(errorResponse.errorDescription)))
                }
            } catch let jsonError {
                os_log("Failed to decode SignOutResponse %@", jsonError.localizedDescription)
                completion(.failure(.jsonError(jsonError)))
            }
            return
        }

        task.resume()
    }

    ///
    /// Get the user object after a succesful sign in
    ///
    func getUser(completion: @escaping (Result<User, UserResponseError>) -> Void) {
        var request = URLRequest(url: baseURL.appendingPathComponent("/users/me"))
        request.httpMethod = HTTPMethod.get
        setHeader(for: &request)

        logRequest(request)

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.sessionError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                completion(.failure(.malformedResponse))
                return
            }
            self.logResponseData(data)

            // Parse response
            do {
                let snakeDecoder = JSONDecoder()
                snakeDecoder.keyDecodingStrategy = .convertFromSnakeCase
                switch httpResponse.statusCode {
                case 200:
                    // success
                    let user = try snakeDecoder.decode(User.self, from: data)
                    completion(.success(user))
                case 400:
                    let errorResponse = try snakeDecoder.decode(ErrorResponse.self, from: data)
                    completion(.failure(.badRequest(errorResponse.errorDescription)))
                case 401:
                    let errorResponse = try snakeDecoder.decode(ErrorResponse.self, from: data)
                    completion(.failure(.unauthorized(errorResponse.errorDescription)))
                case 500:
                    let errorResponse = try snakeDecoder.decode(ErrorResponse.self, from: data)
                    completion(.failure(.internalServerError(errorResponse.errorDescription)))
                default:
                    let errorResponse = try snakeDecoder.decode(ErrorResponse.self, from: data)
                    completion(.failure(.serverError(errorResponse.errorDescription)))
                }
            } catch let jsonError {
                os_log("Failed to decode SignInResponse %@", jsonError.localizedDescription)
                completion(.failure(.jsonError(jsonError)))
            }
            return
        }
        task.resume()
    }

    ///
    /// Set request headers; inject bearer token if available
    ///
    func setHeader(for request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        // Apple discourages setting the Authorization field, but the workaround is complicated
        // https://forums.developer.apple.com/thread/89811
        if let sessionToken = apiToken {
            request.setValue(sessionToken, forHTTPHeaderField: "Authorization")
        }
    }

    func logRequest(_ request: URLRequest) {
        guard let curlRequest = request.curlString else {
            os_log("Failed to log curl for signIn request")
            return
        }
        os_log("API Request: %@", curlRequest)
    }

    func logResponseData(_ data: Data) {
        let dataString = String(data: data, encoding: .utf8) ?? "unable to decode"
        os_log("API Response: %@", dataString)
    }
}

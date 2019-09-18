//
//  DemoAuthService.swift
//  BankApp
//
//  Created by Adam Tierney on 9/11/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import Foundation

/// This service uses a mix of Joint Venture endpoints for performing real token / user info
/// exchanges and mocked responses to supporte demo functionality.
class DemoAuthService {
    enum Env {
        case dev
        case qa
        case prod

        var host: URL {
            switch self {
            case .dev:
                return URL(string: "https://ube-dev.xcijv.com")!
            case .qa: return
                URL(string: "https://ube-qa.xcijv.com")!
            case .prod:
                return URL(string: "https://ube.xcijv.com/")!
            }
        }
    }

    private static let clientId: String = {
        guard let clientId = Bundle.main.infoDictionary?["ZenKeyClientId"] as? String else {
            fatalError("missing client id")
        }
        return clientId
    }()

    fileprivate static let jsonEncoder = JSONEncoder()

    private lazy var env: Env = {
        // toggle qa / prod requires restart so we'll evaluate this once.
        if BuildInfo.isQAHost {
            return .qa
        } else {
            return .prod
        }
    }()

    private let session = URLSession(
        configuration: .ephemeral,
        delegate: nil,
        delegateQueue: Foundation.OperationQueue.main
    )

    func makeRequest(forPath path: String) -> URLRequest {
        guard var components = URLComponents(url: env.host, resolvingAgainstBaseURL: false) else {
            fatalError("invalid url \(env.host)")
        }

        components.path = path
        guard let url = components.url else {
            fatalError("invalid components \(components)")
        }

        var request = URLRequest(url: url)

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        return request
    }
}

extension DemoAuthService: ServiceProviderAPIProtocol {
    func login(withAuthCode code: String,
               redirectURI: URL,
               mcc: String,
               mnc: String,
               completion: @escaping (AuthPayload?, Error?) -> Void) {

        requestToken(withAuthCode: code,
                     redirectURI: redirectURI,
                     mcc: mcc,
                     mnc: mnc) { tokenResponse, error in

                        guard let tokenResponse = tokenResponse else {
                            completion(nil, error)
                            return
                        }

                        UserAccountStorage.setUser(withAccessToken: tokenResponse.accessToken)
                        UserAccountStorage.setMCCMNC(mcc: mcc, mnc: mnc)
                        completion(AuthPayload(token: "my_pretend_auth_token"), nil)
        }
    }

    func addSecondFactor(withAuthCode code: String,
                         redirectURI: URL,
                         mcc: String,
                         mnc: String,
                         completion: @escaping (AuthPayload?, Error?) -> Void) {
        login(withAuthCode: code, redirectURI: redirectURI, mcc: mcc, mnc: mnc, completion: completion)
    }

    func getUserInfo(completion: @escaping (UserInfo?, Error?) -> Void) {
        guard
            let token = UserAccountStorage.accessToken,
            let mccmnc = UserAccountStorage.mccmnc else {
                completion(nil, ServiceError.invalidToken)
                return
        }

        var request = makeRequest(forPath: "/oauth/userinfo")
        let requestBody = UserInfoRequest(
            clientId: DemoAuthService.clientId,
            mcc: mccmnc.mcc,
            mnc: mccmnc.mnc,
            token: token
        )

        guard let body = try? DemoAuthService.jsonEncoder.encode(requestBody) else {
            Logger.log(.error, "unable to encode body from: \(requestBody)")
            completion(nil, ServiceError.unknownError)
            return
        }

        request.httpMethod = "GET"
        request.httpBody = body
        session.requestJSON(request: request) { (userInfoResponse: UserInfoResponse?, error: Error?) in
            let userInfo = userInfoResponse?
                .toUserInfo(withUsername: UserAccountStorage.userName ?? "zenkey_user")
            completion(userInfo, error)
        }
    }

    func requestTransfer(withAuthCode code: String,
                         redirectURI: URL,
                         transaction: Transaction,
                         nonce: String,
                         completion: @escaping (Transaction?, Error?) -> Void) {
        guard
            let mccmnc = UserAccountStorage.mccmnc else {
                completion(nil, ServiceError.invalidToken)
                return
        }

        requestToken(withAuthCode: code,
                     redirectURI: redirectURI,
                     mcc: mccmnc.mcc,
                     mnc: mccmnc.mnc) { [weak self] tokenResponse, error in

                        guard
                            let tokenResponse = tokenResponse,
                            let saveResult = self?.save(transaction: transaction, with: tokenResponse.idToken, matchingNonce: nonce) else {
                            completion(nil, error)
                            return
                        }
                        completion(saveResult.transaction, saveResult.error)
        }
    }

    // MARK: Mock-ish implementations

    func login(withUsername username: String,
               password: String,
               completion: @escaping (AuthPayload?, Error?) -> Void) {
        guard username == "jane", password == "12345" else {
            completion(nil, LoginError.invalidCredentials)
            return
        }

        UserAccountStorage.userName = UserAccountStorage.mockUserName
        DispatchQueue.main.async {
            completion(AuthPayload(token: "my_pretend_auth_token"), nil)
        }
    }

    func getTransactions(completion: @escaping ([Transaction]?, Error?) -> Void) {
        DispatchQueue.main.async {
            completion(UserAccountStorage.getTransactionHistory().reversed(), nil)
        }
    }

    func logout(completion: @escaping (Error?) -> Void) {
        UserAccountStorage.clearUser()
        DispatchQueue.main.async {
            completion(nil)
        }
    }
}

private extension DemoAuthService {

    func requestToken(withAuthCode code: String,
                      redirectURI: URL,
                      mcc: String,
                      mnc: String,
                      completion: @escaping (TokenResponse?, Error?) -> Void) {

        var request = makeRequest(forPath: "/oauth/usertoken")
        let requestBody = TokenRequest(
            clientId: DemoAuthService.clientId,
            code: code,
            redirectURI: redirectURI,
            mcc: mcc,
            mnc: mnc
        )
        guard let body = try? DemoAuthService.jsonEncoder.encode(requestBody) else {
            Logger.log(.error, "unable to encode body from: \(requestBody)")
            completion(nil, ServiceError.unknownError)
            return
        }
        request.httpMethod = "POST"
        request.httpBody = body
        session.requestJSON(request: request) { (result: TokenResponse?, error: Error?) in
            guard let result = result, error == nil else {
                completion(nil, error)
                return
            }

            UserAccountStorage.setUser(withAccessToken: result.accessToken)
            UserAccountStorage.setMCCMNC(mcc: mcc, mnc: mnc)

            completion(result, error)
        }
    }
}

// MARK: - Requests

private struct TokenRequest: Encodable {
    let code: String
    let redirectURI: String
    let clientId: String
    let mccmnc: String

    init(clientId: String, code: String, redirectURI: URL, mcc: String, mnc: String) {
        self.clientId = clientId
        self.code = "Bearer \(code)"
        self.redirectURI = redirectURI.absoluteString
        self.mccmnc = "\(mcc)\(mnc)"
    }

    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case redirectURI = "redirect_uri"
        case code
        case mccmnc
    }
}

private struct UserInfoRequest: Encodable {
    let token: String
    let clientId: String
    let mccmnc: String

    init(clientId: String, mcc: String, mnc: String, token: String) {
        self.clientId = clientId
        self.mccmnc = "\(mcc)\(mnc)"
        self.token = token
    }

    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case mccmnc
        case token
    }
}

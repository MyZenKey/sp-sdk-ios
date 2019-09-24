//
//  ClientSideService.swift
//  BankApp
//
//  Created by Adam Tierney on 7/31/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import Foundation

class ClientSideService: ServiceProviderAPIProtocol {

    private static let clientId: String = {
        guard let clientId = Bundle.main.infoDictionary?["ZenKeyClientId"] as? String else {
            fatalError("missing client id")
        }
        return clientId
    }()
    private static let appSecret: String = {
        guard let appSecret = Bundle.main.infoDictionary?["ZenKeyAppSecret"] as? String else {
            return ""
        }
        return appSecret
    }()
    private static let authHeaderValue: String = {
        let encodedValue = "\(clientId):\(appSecret)".data(using: .utf8)!.base64EncodedString()
        return "Basic \(encodedValue)"
    }()

    private static var config: [String: DiscoveryResponse] = [:]
    private static let jsonEncoder = JSONEncoder()

    private let session = URLSession(
        configuration: .ephemeral,
        delegate: nil,
        delegateQueue: Foundation.OperationQueue.main
    )

    func login(withAuthCode code: String,
               redirectURI: URL,
               mcc: String,
               mnc: String,
               completion: @escaping (AuthPayload?, Error?) -> Void) {

        requestToken(forMCC: mcc,
                     andMNC: mnc,
                     redirectURI: redirectURI,
                     authorizationCode: code) { tokenResponse, error in
            guard let tokenResponse = tokenResponse else {
                completion(nil, error)
                return
            }

            UserAccountStorage.setUser(withAccessToken: tokenResponse.accessToken)
            UserAccountStorage.setMCCMNC(mcc: mcc, mnc: mnc)
            completion(AuthPayload(token: "my_pretend_auth_token"), nil)
        }
    }

    func login(
        withUsername username: String,
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

    func addSecondFactor(
        withAuthCode code: String,
        redirectURI: URL,
        mcc: String,
        mnc: String,
        completion: @escaping (AuthPayload?, Error?) -> Void) {

        login(withAuthCode: code, redirectURI: redirectURI, mcc: mcc, mnc: mnc, completion: completion)
    }

    func getUserInfo(completion: @escaping (UserInfo?, Error?) -> Void) {

        guard !UserAccountStorage.isMockUser else {
            completion(UserAccountStorage.mockUserInfo, nil)
            return
        }

        guard
            let token = UserAccountStorage.accessToken,
            let mccmnc = UserAccountStorage.mccmnc else {
            completion(nil, ServiceError.invalidToken)
            return
        }

        getOIDC(forMCC: mccmnc.mcc,
                andMNC: mccmnc.mnc,
                handleError: { completion(nil, $0) }) { [weak self] oidc in
                    guard let sself = self else { return }
                    var request = URLRequest(url: oidc.userInfoEndpoint)
                    request.httpMethod = "GET"
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.addValue("application/json", forHTTPHeaderField: "Accept")
                    sself.session.requestJSON(request: request) { (userInfoResponse: UserInfoResponse?, error: Error?) in
                        let userInfo = userInfoResponse?
                            .toUserInfo(withUsername: UserAccountStorage.userName ?? "zenkey_user")
                        completion(userInfo, error)
                    }
        }
    }

    func requestTransfer(withAuthCode code: String,
                         redirectURI: URL,
                         transaction: Transaction,
                         nonce: String,
                         completion: @escaping (Transaction?, Error?) -> Void) {

        guard
            let mccmnc = UserAccountStorage.mccmnc else {
                completion(nil, ServiceError.unknownError)
                return
        }

        requestToken(forMCC: mccmnc.mcc,
                     andMNC: mccmnc.mnc,
                     redirectURI: redirectURI,
                     authorizationCode: code) { [weak self] tokenResponse, error in

                        guard
                            let tokenResponse = tokenResponse,
                            let saveResult = self?.save(transaction: transaction, with: tokenResponse.idToken, matchingNonce: nonce) else {
                                completion(nil, error)
                                return
                        }
                        completion(saveResult.transaction, saveResult.error)
        }
    }

    func getTransactions(completion: @escaping ([Transaction]?, Error?) -> Void) {
        completion(UserAccountStorage.getTransactionHistory().reversed(), nil)
    }

    func logout(completion: @escaping (Error?) -> Void) {
        UserAccountStorage.clearUser()
        DispatchQueue.main.async {
            completion(nil)
        }
    }
}

private extension ClientSideService {
    func getOIDC(forMCC mcc: String,
                 andMNC mnc: String,
                 handleError: @escaping (Error?) -> Void,
                 completion: @escaping (DiscoveryResponse) -> Void) {
        getOIDC(mcc: mcc, mnc: mnc) { oidc, error in
            guard let oidc = oidc else {
                handleError(error)
                return
            }
            completion(oidc)
        }
    }

    func getOIDC(mcc: String,
                 mnc: String,
                 completion: @escaping (DiscoveryResponse?, Error?) -> Void) {

        let key = "\(mcc)\(mnc)"
        if let config = ClientSideService.config[key] {
            completion(config, nil)
        } else {
            discovery(mcc: mcc, mnc: mnc) { result, error in
                if let result = result {
                    ClientSideService.config[key] = result
                }
                completion(result, error)
            }
        }
    }

    func discovery(mcc: String,
                   mnc: String,
                   completion: @escaping (DiscoveryResponse?, Error?) -> Void) {
        let endpoint = URLRequest(url: discoveryEndpoint(mcc: mcc, mnc: mnc))
        session.requestJSON(request: endpoint, completion: completion)
    }

    func requestToken(forMCC mcc: String,
                      andMNC mnc: String,
                      redirectURI: URL,
                      authorizationCode code: String,
                      completion: @escaping (TokenResponse?, Error?) -> Void) {

        getOIDC(forMCC: mcc,
                andMNC: mnc,
                handleError: { completion(nil, $0) }) { [weak self] oidc in

                    guard let sself = self else { return }

                    var request = URLRequest(url: oidc.tokenEndpoint)
                    request.httpMethod = "POST"
                    request.addValue(ClientSideService.authHeaderValue, forHTTPHeaderField: "Authorization")
                    request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                    let tokenRequest = TokenRequest(
                        clientId: ClientSideService.clientId,
                        code: code,
                        redirectURI: redirectURI
                    )
                    let encoded = tokenRequest.formURLEncodedData

                    request.httpBody = encoded
                    sself.session.requestJSON(request: request, completion: completion)
        }
    }

    func discoveryEndpoint(mcc: String, mnc: String) -> URL {
        let params: [String: String] = [
            "client_id": ClientSideService.clientId,
            "mccmnc": "\(mcc)\(mnc)",
        ]

        let url: URL
        if BuildInfo.isQAHost {
            url = URL(string: "https://discoveryissuer-qa.myzenkey.com/.well-known/openid_configuration")!
        } else {
            url = URL(string: "https://discoveryissuer.myzenkey.com/.well-known/openid_configuration")!
        }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = params.map() { return URLQueryItem(name: $0, value: $1)  }
        return components.url!
    }
}

// MARK: - Requests

private struct TokenRequest: Encodable {
    let grantType = "authorization_code"
    let code: String
    let redirectURI: String

    init(clientId: String, code: String, redirectURI: URL) {
        self.code = code
        self.redirectURI = redirectURI.absoluteString
    }

    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case redirectURI = "redirect_uri"
        case code
    }

    let encodeValue: (String) -> String? = {
        return $0.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
    }

    var formURLEncodedData: Data {
        // from MDN: https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST
        // > application/x-www-form-urlencoded: the keys and values are encoded in key-value tuples
        // > separated by '&', with a '=' between the key and the value. Non-alphanumeric characters
        // > in both keys and values are percent encoded: this is the reason why this type is not
        // > suitable to use with binary data (use multipart/form-data instead)
        let query = [
            CodingKeys.grantType.rawValue: grantType,
            CodingKeys.redirectURI.rawValue: redirectURI,
            CodingKeys.code.rawValue: code,
            ]
            .reduce([String]()) { acc, next in
                guard
                    let encodedKey = encodeValue(next.key),
                    let encodedValue = encodeValue(next.value) else {
                        return acc
                }
                var acc = acc
                acc.append("\(encodedKey)=\(encodedValue)")
                return acc
            }
            .joined(separator: "&")

        return query.data(using: .utf8)!
    }
}

// MARK: - Responses

private struct DiscoveryResponse: Decodable {
    let tokenEndpoint: URL
    let userInfoEndpoint: URL

    enum CodingKeys: String, CodingKey {
        case tokenEndpoint = "token_endpoint"
        case userInfoEndpoint = "userinfo_endpoint"
    }
}

//
//  LocalAuthService.swift
//  BankApp
//
//  Created by Adam Tierney on 7/31/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import Foundation

struct AuthPayload {
    let token: String
}
struct UserInfo {
    let email: String?
    let name: String?
    let givenName: String?
    let familyName: String?
    let birthdate: String?
    let postalCode: String?
}

struct Trasnaction {}

protocol ServiceAPIProtocol {
    func login(
        withAuthCode code: String,
        mcc: String,
        mnc: String,
        completion: @escaping (AuthPayload?, Error?) -> Void)

    func getUserInfo(completion: @escaping (UserInfo?, Error?) -> Void)

    func approve(transferIdentifier: String,
                 userContext: String,
                 nonce: String,
                 completion: (Trasnaction?, Error?) -> Void)

    func logout(completion: @escaping (Error?) -> Void)
}

struct TokenRequest: Encodable {
    let grantType = "authorization_code"
    let code: String
    let redirectURI: String

    init(clientId: String, code: String) {
        self.code = code
        self.redirectURI = "\(clientId)://com.xci.provider.sdk"
    }

    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case redirectURI = "redirect_uri"
        case code
    }

    var urlFormEncodedData: Data {
        var components = URLComponents()
        components.queryItems = [
            CodingKeys.grantType.rawValue: grantType,
            CodingKeys.redirectURI.rawValue: redirectURI,
            CodingKeys.code.rawValue: code,
        ]
        .map { key, value in URLQueryItem(name: key, value: value) }

        guard let query = components.percentEncodedQuery else {
            fatalError("unable to percent encode query components")
        }
        return query.data(using: .utf8)!
    }
}

struct UserInfoResponse: Codable {
    let sub: String
    let name: String?
    let givenName: String?
    let familyName: String?
    let birthdate: String?
    let email: String?
    let postalCode: String?

    enum CodingKeys: String, CodingKey {
        case sub
        case name
        case givenName = "given_name"
        case familyName = "family_name"
        case birthdate = "birthdate"
        case email = "email"
        case postalCode = "postal_code"
    }

    fileprivate var toUserInfo: UserInfo {
        return UserInfo(
            email: email,
            name: name,
            givenName: givenName,
            familyName: familyName,
            birthdate: birthdate,
            postalCode: postalCode
        )
    }
}

struct TokenResponse: Codable {
    let idToken: String
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}

struct DiscoveryResponse: Decodable {
    let tokenEndpoint: URL
    let userInfoEndpoint: URL

    enum CodingKeys: String, CodingKey {
        case tokenEndpoint = "token_endpoint"
        case userInfoEndpoint = "userinfo_endpoint"
    }
}

class ClientSideServiceAPI: ServiceAPIProtocol {

    private static let clientId: String = {
        guard let clientId = Bundle.main.infoDictionary?["ProjectVerifyClientId"] as? String else {
            fatalError("missing client id")
        }
        return clientId
    }()
    private static let appSecret: String = {
        guard let appSecret = Bundle.main.infoDictionary?["ProjectVerifyAppSecret"] as? String else {
            return ""
        }
        return appSecret
    }()
    private static let authHeaderValue: String = {
        let encodedValue = "\(clientId):\(appSecret)".data(using: .utf8)!.base64EncodedString()
        return "Basic \(encodedValue)"
    }()

    private static var config: [String: DiscoveryResponse] = [:]
    private static let jsonDecoder = JSONDecoder()
    private static let jsonEncoder = JSONEncoder()

    private let session = URLSession(
        configuration: .ephemeral,
        delegate: nil,
        delegateQueue: Foundation.OperationQueue.main
    )

    func login(withAuthCode code: String,
               mcc: String,
               mnc: String,
               completion: @escaping (AuthPayload?, Error?) -> Void) {

        getOIDC(forMCC: mcc,
                andMNC: mnc,
                handleError: { completion(nil, $0) }) { [weak self] oidc in

            guard let sself = self else { return }

            var request = URLRequest(url: oidc.tokenEndpoint)
            request.httpMethod = "POST"
            request.addValue(ClientSideServiceAPI.authHeaderValue, forHTTPHeaderField: "Authorization")
            request.addValue("Accept", forHTTPHeaderField: "application/x-www-form-urlencoded")
            let tokenRequest = TokenRequest(
                clientId: ClientSideServiceAPI.clientId,
                code: code
            )
            let encoded = tokenRequest.urlFormEncodedData

            request.httpBody = encoded
            sself.requestJSON(request: request) { (tokenResponse: TokenResponse?, error: Error?) in
                guard let tokenResponse = tokenResponse else {
                    completion(nil, error)
                    return
                }

                UserAccountStorage.setUser(withTokenResponse: tokenResponse)
                UserAccountStorage.setMCCMNC(mcc: mcc, mnc: mnc)
                completion(AuthPayload(token: "my_pretend_auth_token"), nil)
            }
        }
    }

    func getUserInfo(completion: @escaping (UserInfo?, Error?) -> Void) {
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
                    request.addValue("Accept", forHTTPHeaderField: "application/json")
                    sself.requestJSON(request: request) { (userInfoResponse: UserInfoResponse?, error: Error?) in
                        completion(userInfoResponse?.toUserInfo, error)
                    }
        }
    }

    func approve(transferIdentifier: String,
                 userContext: String,
                 nonce: String,
                 completion: (Trasnaction?, Error?) -> Void) {

    }

    func getOIDC(forMCC mcc: String,
                andMNC mnc: String,
                handleError: @escaping (Error?) -> Void,
                then: @escaping (DiscoveryResponse) -> Void) {
        getOIDC(mcc: mcc, mnc: mnc) { oidc, error in
            guard let oidc = oidc else {
                handleError(error)
                return
            }
            then(oidc)
        }
    }

    func logout(completion: @escaping (Error?) -> Void) {
        UserAccountStorage.clearUser()
        DispatchQueue.main.async {
            completion(nil)
        }
    }
}

private extension ClientSideServiceAPI {

    func getOIDC(mcc: String,
                 mnc: String,
                 completion: @escaping (DiscoveryResponse?, Error?) -> Void) {

        let key = "\(mcc)\(mnc)"
        if let config = ClientSideServiceAPI.config[key] {
            completion(config, nil)
        } else {
            discovery(mcc: mcc, mnc: mnc) { result, error in
                if let result = result {
                    ClientSideServiceAPI.config[key] = result
                }
                completion(result, error)
            }
        }
    }

    func discovery(mcc: String,
                   mnc: String,
                   completion: @escaping (DiscoveryResponse?, Error?) -> Void) {
        let endpoint = URLRequest(url: discoveryEndpoint(mcc: mcc, mnc: mnc))
        requestJSON(request: endpoint, completion: completion)
    }

    func requestJSON<T: Decodable>(
        request: URLRequest,
        completion: @escaping (T?, Error?) -> Void) {
        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                var result: T?
                var errorResult: Error? = error

                defer { completion(result, errorResult) }

                if let statusError = (response as? HTTPURLResponse)?.errorValue, error == nil {
                    errorResult = statusError
                }

                guard errorResult == nil, let data = data else {
                    return
                }
                do {
                    result = try ClientSideServiceAPI.jsonDecoder.decode(
                        T.self,
                        from: data
                    )
                } catch let parseError {
                    errorResult = parseError
                }
            }
        }
        task.resume()
    }

    func discoveryEndpoint(mcc: String, mnc: String) -> URL {
        let params: [String: String] = [
            "client_id": ClientSideServiceAPI.clientId,
            "mccmnc": "\(mcc)\(mnc)",
        ]
        let url = URL(string: "https://discoveryissuer.xcijv.com/.well-known/openid_configuration")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = params.map() { return URLQueryItem(name: $0, value: $1)  }
        return components.url!
    }
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

extension Data {
    func printJSON() {
        do {
            let json = try JSONSerialization.jsonObject(with: self, options: [.allowFragments])
            print(json)
        } catch {
            print("invalid json")
        }
    }
}

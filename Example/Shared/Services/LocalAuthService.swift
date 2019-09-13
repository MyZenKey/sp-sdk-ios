//
//  LocalAuthService.swift
//  BankApp
//
//  Created by Adam Tierney on 7/31/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import Foundation

struct TokenRequest: Encodable {
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

    var urlFormEncodedData: Data {
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

    fileprivate func toUserInfo(withUsername username: String) -> UserInfo {
        return UserInfo(
            username: username,
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

class ClientSideServiceAPI: ServiceProviderAPIProtocol {

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
    private static let jsonDecoder = JSONDecoder()
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

            UserAccountStorage.setUser(withTokenResponse: tokenResponse)
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

        UserAccountStorage.userName = ClientSideServiceAPI.mockUserName
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

        guard !isMockUser else {
            completion(ClientSideServiceAPI.mockUserInfo, nil)
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
                    sself.requestJSON(request: request) { (userInfoResponse: UserInfoResponse?, error: Error?) in
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
                completion(nil, ServiceError.invalidToken)
                return
        }

        requestToken(forMCC: mccmnc.mcc, andMNC: mccmnc.mnc, redirectURI: redirectURI, authorizationCode: code) { tokenResponse, error in
            guard let tokenResponse = tokenResponse else {
                completion(nil, error)
                return
            }

            // ensure integrity of request
            let idToken = tokenResponse.idToken
            guard let parsed = idToken.simpleDecodeTokenBody() else {
                completion(nil, TransactionError.unableToParseToken)
                return
            }

            let returnedContext = parsed["context"] as? String
            let returnedNonce = parsed["nonce"] as? String

            guard returnedContext == transaction.contextString, returnedNonce == nonce else {
                completion(nil, TransactionError.mismatchedTransaction)
                return
            }

            // Build new timestamped Transaction
            let completedTransaction = Transaction(time: Date(),
                                                   recipiant: transaction.recipiant,
                                                   amount: transaction.amount)

            var transactions = UserAccountStorage.getTransactionHistory()
            transactions.append(completedTransaction)
            UserAccountStorage.setTransactionHistory(transactions)

            completion(completedTransaction, nil)
        }
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

private extension ClientSideServiceAPI {

    static let mockUserName = "jane"

    static let mockUserInfo = UserInfo(
        username: ClientSideServiceAPI.mockUserName,
        email: "janedoe@rightpoint.com",
        name: "Jane",
        givenName: "Jane",
        familyName: "Doe",
        birthdate: "1/1/1000",
        postalCode: "00000"
    )

    var isMockUser: Bool {
        return UserAccountStorage.userName == ClientSideServiceAPI.mockUserName
    }

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
                    request.addValue(ClientSideServiceAPI.authHeaderValue, forHTTPHeaderField: "Authorization")
                    request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                    let tokenRequest = TokenRequest(
                        clientId: ClientSideServiceAPI.clientId,
                        code: code,
                        redirectURI: redirectURI
                    )
                    let encoded = tokenRequest.urlFormEncodedData

                    request.httpBody = encoded
                    sself.requestJSON(request: request, completion: completion)
        }
    }

    func requestJSON<T: Decodable>(
        request: URLRequest,
        completion: @escaping (T?, Error?) -> Void) {

        ClientSideServiceAPI.log("performing request: \(request)")
        ClientSideServiceAPI.log(request: request)
        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                ClientSideServiceAPI.log("concluding request: \(request.url!) with: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
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

extension String {
    /// you should use a tool to support token decoding. this just hacks the base64url encoded
    /// body back to base64, then to json so we don't need to take on dependencies.
    func simpleDecodeTokenBody() -> [String: Any]? {
        let bodyBase64URLString = self.split(separator: ".")[1]
        var bodyBase64String = bodyBase64URLString
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")

        let length = Double(bodyBase64String.lengthOfBytes(using: .utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            bodyBase64String = bodyBase64String + padding
        }
        guard let data = Data(base64Encoded: bodyBase64String, options: .ignoreUnknownCharacters) else {
            ClientSideServiceAPI.log("Warning: unable to parse JWT")
            return nil
        }

        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return nil
            }

            return json
        } catch {
            ClientSideServiceAPI.log("Warning: unable to parse JWT")
            return nil
        }
    }
}

extension Data {
    func printJSON() {
        do {
            let json = try JSONSerialization.jsonObject(with: self, options: [])
            ClientSideServiceAPI.log("\(json)")
        } catch {
            ClientSideServiceAPI.log("invalid json")
        }
    }
}

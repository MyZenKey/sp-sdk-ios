//
//  LocalAuthService.swift
//  BankApp
//
//  Created by Adam Tierney on 7/31/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import Foundation

struct AuthPayload {}
struct UserInfo {}
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
}

enum AppResources {
    case login
    case userInfo
    case transaction
}

struct TokenRequest: Encodable {
    let grantType = "authorization_code"
    let clientId: String
    let code: String
    let redirectURI: String

    init(clientId: String, code: String) {
        self.clientId = clientId
        self.code = code
        self.redirectURI = "\(clientId)://com.xci.provider.sdk"
    }

    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case clientId = "client_id"
        case redirectURI = "redirect_uri"
    }
}

struct TokenResponse: Decodable {
    let idToken: String

    enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
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
    private static let clientSecret: String = {
        guard let clientId = Bundle.main.infoDictionary?["ProjectVerifyClientSecret"] as? String else {
            fatalError("missing client secret")
        }
        return ""
    }()
    private static let authHeaderValue: String = {
        return "\(clientId):\(clientSecret)".data(using: .utf8)!.base64EncodedString()
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
            let tokenRequest = TokenRequest(
                clientId: ClientSideServiceAPI.clientId,
                code: code
            )
            do {
                request.httpBody = try ClientSideServiceAPI.jsonEncoder.encode(tokenRequest)
                sself.requestJSON(request: request) { (tokenResponse: TokenResponse?, error: Error?) in
                    print("$$$ \(tokenResponse), error: \(error)")
                }
            } catch let encodingError {
                completion(nil, encodingError)
            }
        }
    }

    func getUserInfo(completion: @escaping (UserInfo?, Error?) -> Void) {

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
}

private extension ClientSideServiceAPI {
    func requestJSON<T: Decodable>(
        request: URLRequest,
        completion: @escaping (T?, Error?) -> Void) {
        let task = session.dataTask(with: request) { data, response, error in

            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    print(json)
                } catch {
                    //noop
                }
            }

            DispatchQueue.main.async {
                var result: T?
                var errorResult: Error? = error

                defer { completion(result, errorResult) }

                guard error == nil, let data = data else {
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

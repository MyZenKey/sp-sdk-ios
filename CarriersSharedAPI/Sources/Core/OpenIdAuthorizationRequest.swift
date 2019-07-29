//
//  OpenIdAuthorizationRequest.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 7/26/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

enum ResponseType: String {
    case code
}

struct OpenIdAuthorizationRequest: Equatable {
    let resource: URL
    let parameters: Parameters
}

extension OpenIdAuthorizationRequest {
    struct Parameters: Equatable {
        let clientId: String
        let redirectURL: URL
        let formattedScopes: String
        let state: String?
        let nonce: String?

        let acrValues: [ACRValue]?
        let prompt: PromptValue?
        let correlationId: String?
        let context: String?
        var loginHintToken: String?

        init(clientId: String,
             redirectURL: URL,
             formattedScopes: String,
             state: String?,
             nonce: String?,
             acrValues: [ACRValue]?,
             prompt: PromptValue?,
             correlationId: String?,
             context: String?,
             loginHintToken: String?) {

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
        }

        var base64EncodedContext: String? {
            guard let context = context else {
                return nil
            }
            // utf8 will encode all for all swift strings:
            return context.data(using: .utf8)!
                .base64EncodedString()
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
            URLQueryItem(name: Keys.context.rawValue, value: parameters.base64EncodedContext),
            URLQueryItem(name: Keys.prompt.rawValue, value: parameters.prompt?.rawValue),
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

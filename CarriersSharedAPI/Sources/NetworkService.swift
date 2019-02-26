//
//  NetworkService.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/25/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

enum NetworkServiceErrors: Error {
    case invalidResponseBody(request: URLRequest)

    var errorDescription: String {
        switch self {
        case .invalidResponseBody(let request):
            return "unable to serialize response for \(request) – expected valid JSON"
        }
    }
}

protocol NetworkServiceProtocol {
    func requestJSON(request: URLRequest,
                     completion: ((JsonDocument?, Error?) -> Void)?)
}

class NetworkService: NetworkServiceProtocol {
    func requestJSON(request: URLRequest,
                     completion: ((JsonDocument?, Error?) -> Void)?) {

        let task = URLSession.shared.dataTask(with: request) { (data, rawResponse, error) in
            guard error == nil else {
                completion?(nil, error)
                return
            }

            guard let data = data else {
                completion?(nil, NetworkServiceErrors.invalidResponseBody(request: request))
                return
            }
            // TODO: factor out custom att's JSON parser and use codable models
            let document = JsonDocument(data: data)
            completion?(document, nil)
        }

        task.resume()
    }
}

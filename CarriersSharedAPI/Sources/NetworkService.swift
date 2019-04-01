//
//  NetworkService.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/25/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

enum NetworkServiceError: Error {
    case networkError(Error)
    case invalidResponseBody(request: URLRequest)
    case decodingError(DecodingError)
    case unknownError(Error)
}

protocol NetworkServiceProtocol {
    func requestJSON<T: Decodable>(
        request: URLRequest,
        completion: @escaping (Result<T, NetworkServiceError>) -> Void)
}

class NetworkService: NetworkServiceProtocol {
    let jsonDecoder = JSONDecoder()
    
    let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    func requestJSON<T: Decodable>(
        request: URLRequest,
        completion: @escaping (Result<T, NetworkServiceError>) -> Void) {
        
        let decoder = self.jsonDecoder
        let task = URLSession.shared.dataTask(with: request) { (data, rawResponse, error) in
            DispatchQueue.main.async {
                completion(
                    JSONResponseParser.parseDecodable(
                        with: decoder,
                        fromData: data,
                        request: request,
                        error: error
                    )
                )
            }
        }
        task.resume()
    }
}

extension NetworkService {
    struct JSONResponseParser {
        static func parseDecodable<T: Decodable>(
            with decoder: JSONDecoder,
            fromData data: Data?,
            request: URLRequest,
            error: Error?) -> Result<T, NetworkServiceError> {
            
            guard error == nil else {
                return .error(.networkError(error!))
            }
            
            guard let data = data else {
                return .error(NetworkServiceError.invalidResponseBody(request: request))
            }
            
            do {
                let parsed: T = try decoder.decode(T.self, from: data)
                return .value(parsed)
            } catch let decodingError as DecodingError {
                return .error(.decodingError(decodingError))
            } catch {
                return .error(.unknownError(error))
            }
        }
    }
}

//
//  MockNetworkService.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 2/25/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
@testable import ZenKeySDK

class MockNetworkService: NetworkServiceProtocol {
    private var mockJSON: [String: Any]?
    private var mockError: NetworkServiceError?

    var lastRequest: URLRequest?

    func mockJSON(_ json: [String: Any]) {
        mockError = nil
        mockJSON = json
    }

    func mockError(_ error: NetworkServiceError) {
        mockJSON = nil
        mockError = error
    }

    func clear() {
        lastRequest = nil
        mockError = nil
        mockJSON = nil
    }

    let jsonDecoder = JSONDecoder()

    func requestJSON<T>(
        request: URLRequest,
        completion: @escaping (Result<T, NetworkServiceError>) -> Void) where T: Decodable {

        self.lastRequest = request
        let mockJSON = self.mockJSON
        let mockError = self.mockError
        let decoder = jsonDecoder
        DispatchQueue.main.async {
            if let mockJSON = mockJSON {
                guard let data = try? JSONSerialization.data(withJSONObject: mockJSON, options: []) else {
                    fatalError("unable to parse mock json, check your mocks")
                }

                let parsed: Result<T, NetworkServiceError> = NetworkService.JSONResponseParser
                    .parseDecodable(
                        with: decoder,
                        fromData: data,
                        request: request,
                        error: nil
                )

                completion(parsed)
            }

            if let mockError = mockError {
                completion(.failure(mockError))
            }
        }
    }
}

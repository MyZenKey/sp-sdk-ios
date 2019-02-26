//
//  MockNetworkService.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/25/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
@testable import CarriersSharedAPI

class MockNetworkService: NetworkServiceProtocol {

    private var mockJSON: [String: Any]?
    private var mockError: Error?

    var lastRequest: URLRequest?

    func mockJSON(_ json: [String: Any]) {
        mockError = nil
        mockJSON = json
    }

    func mockError(_ error: Error) {
        mockJSON = nil
        mockError = error
    }

    func clear() {
        lastRequest = nil
        mockError = nil
        mockJSON = nil
    }

    func requestJSON(request: URLRequest, completion: ((JsonDocument?, Error?) -> Void)?) {
        self.lastRequest = request
        let mockJSON = self.mockJSON
        let mockError = self.mockError
        DispatchQueue.main.async {
            if let mockJSON = mockJSON {
                completion?(JsonDocument(object: mockJSON), nil)
            }

            if let mockError = mockError {
                completion?(nil, mockError)
            }
        }
    }
}

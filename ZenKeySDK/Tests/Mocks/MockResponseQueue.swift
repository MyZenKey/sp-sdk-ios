//
//  MockResponseQueue.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 6/6/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

class MockResponseQueue<T> {
    /// FIFO responses
    var mockResponses: [T] = []

    /// if this flag is set, the final response configured will be repeated indefinitely
    var repeatLastResponse: Bool = true

    let defaultResponses: [T]

    init(_ defaultResponses: [T] = []) {
        self.defaultResponses = defaultResponses
        self.mockResponses = defaultResponses
    }

    func clear() {
        self.mockResponses = defaultResponses
    }

    func getResponse() -> T {
        guard let result = self.mockResponses.first else {
            fatalError("not enough reponses configured")
        }

        if mockResponses.count > 1 || !repeatLastResponse {
            self.mockResponses = Array(self.mockResponses.dropFirst())
        }

        return result
    }
}

//
//  MockResponseQueue.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 6/6/19.
//  Copyright © 2019 ZenKey, LLC. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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

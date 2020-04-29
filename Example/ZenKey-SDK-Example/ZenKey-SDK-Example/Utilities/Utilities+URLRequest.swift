//
//  Utilities+URLRequest.swift
//  ZenKeySDK
//
//  Created by Sawyer Billings on 2/18/20.
//  Copyright © 2020 ZenKey, LLC.
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

extension URLRequest {
    var curlString: String? {
        guard
            let url = url,
            let method = httpMethod else {
                return nil
        }

        var curlString = "curl -v -X \(method) \\\n"
        allHTTPHeaderFields?.forEach() { key, value in
            curlString += "-H '\(key): \(value)' \\\n"
        }

        if
            let httpBody = httpBody,
            var bodyString = String(data: httpBody, encoding: .utf8) {
            // escape quotes:
            bodyString = bodyString.replacingOccurrences(of: "\"", with: "\\\"")

            curlString += "-d \"\(bodyString)\" \\\n"
        }

        curlString += "\"\(url.absoluteString)\"\n"

        return curlString
    }
}

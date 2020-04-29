//
//  UserResponse.swift
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

struct User: Decodable {
    let zenkeySub: String
    let userId: Int
    let username: String?
    let name: String?
    let email: String?
    let postalCode: String?
    let phoneNumber: String?
}

enum UserResponseError: Error {
    case serverError(String)
    case badRequest(String)
    case unauthorized(String)
    case internalServerError(String)
    case jsonError(Error)
    case sessionError(Error)
    case malformedResponse
}

extension UserResponseError: LocalizedError {
    var errorDescription: String? {
         var errorDescription: String
         switch self {
         case .serverError(let errorString):
             errorDescription = errorString
         case .badRequest(let errorString):
             errorDescription = errorString
         case .unauthorized(let errorString):
             errorDescription = errorString
         case .internalServerError(let errorString):
             errorDescription = errorString
         case .jsonError(let error):
             errorDescription = error.localizedDescription
         case .sessionError(let error):
             errorDescription = error.localizedDescription
         case .malformedResponse:
             errorDescription = Localized.Error.unrecognized
         }
         return errorDescription
    }
}

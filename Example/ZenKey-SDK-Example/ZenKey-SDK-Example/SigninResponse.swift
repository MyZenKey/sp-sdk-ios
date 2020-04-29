//
//  SignInResponse.swift
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

struct SignInResponse: Decodable {
    let token: String
    let refreshToken: String
    let tokenType: String
    let expires: Int
}

enum SignInError: Error {
    case unlinkedUser(UnlinkedResponse)
    case serverError(String)
    case badRequest(String)
    case unauthorized(String)
    case internalServerError(String)
    case jsonError(Error)
    case sessionError(Error)
    case malformedResponse
}

extension SignInError: LocalizedError {
    var errorDescription: String? {
         var errorDescription: String
         switch self {
         case .unlinkedUser(let unlinkedData):
            errorDescription = unlinkedData.errorDescription
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

struct UnlinkedResponse: Decodable {
    let zenkeyAttributes: ZenKeyAttributes
    let error: String
    let errorDescription: String
}

enum SignOutError: Error {
    case serverError(String)
    case unauthorized(String)
    case internalServerError(String)
    case jsonError(Error)
    case sessionError(Error)
    case malformedResponse
}

extension SignOutError: LocalizedError {
    var errorDescription: String? {
         var errorDescription: String
         switch self {
         case .serverError(let errorString):
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

struct ZenKeyAttributes: Decodable {
    let sub: String
    let name: String?
    let phoneNumber: String?
    let postalCode: String?
    let email: String?
}

struct ErrorResponse: Decodable {
    let error: String
    let errorDescription: String
}

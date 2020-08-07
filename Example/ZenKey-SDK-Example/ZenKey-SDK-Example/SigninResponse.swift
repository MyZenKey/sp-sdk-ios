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

// Expects to be decoded with JSONEncoder's keyDecodingStrategy set to .convertFromSnakeCase
struct ZenKeyAttributes: Decodable {
    let sub: String
    let name: ZenKeyAttributesNameValue?
    let birthdate: ZenKeyAttributesStringValue?
    let email: ZenKeyAttributesStringValue?
    let picture: ZenKeyAttributesStringValue?
    let address: ZenKeyAttributesAddressValue?
    let postalCode: ZenKeyAttributesStringValue?
    let phone: ZenKeyAttributesStringValue?
    let isAdult18: ZenKeyAttributesBoolValue?
    let isAdult21: ZenKeyAttributesBoolValue?
    let isOver13: ZenKeyAttributesBoolValue?
    let last4Social: ZenKeyAttributesStringValue?

    enum CodingKeys: String, CodingKey {
        case sub, name, birthdate, email, picture, address, phone
        case postalCode, last4Social, isAdult18, isAdult21, isOver13
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sub = try values.decode(String.self, forKey: .sub)
        name = try? values.decode(ZenKeyAttributesNameValue.self, forKey: .name)
        birthdate = try? values.decode(ZenKeyAttributesStringValue.self, forKey: .birthdate)
        email = try? values.decode(ZenKeyAttributesStringValue.self, forKey: .email)
        picture = try? values.decode(ZenKeyAttributesStringValue.self, forKey: .picture)
        address = try? values.decode(ZenKeyAttributesAddressValue.self, forKey: .address)
        postalCode = try? values.decode(ZenKeyAttributesStringValue.self, forKey: .postalCode)
        phone = try? values.decode(ZenKeyAttributesStringValue.self, forKey: .phone)
        isAdult18 = try? values.decode(ZenKeyAttributesBoolValue.self, forKey: .isAdult18)
        isAdult21 = try? values.decode(ZenKeyAttributesBoolValue.self, forKey: .isAdult21)
        isOver13 = try? values.decode(ZenKeyAttributesBoolValue.self, forKey: .isOver13)
        last4Social = try? values.decode(ZenKeyAttributesStringValue.self, forKey: .last4Social)
    }
}
struct ZenKeyAttributesStringValue: Decodable {
    let value: String
}
struct ZenKeyAttributesBoolValue: Decodable {
    let value: Bool
}
struct ZenKeyAttributesNameValue: Decodable {
    let value: String
    let givenName: String
    let familyName: String
}
struct ZenKeyAttributesAddressValue: Codable {
    let formatted: String?
    let streetAddress: String?
    let locality: String?
    let region: String?
    let postalCode: String?
    let country: String?
}

struct ErrorResponse: Decodable {
    let error: String
    let errorDescription: String
}

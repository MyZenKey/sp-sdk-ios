//
//  AuthorizationServiceCurrentRequestStorage.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 6/24/19.
//  Copyright © 2019 XCI JV, LLC.
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

//swiftlint:disable type_name

/// Weakly holds a pointer to the last authorization service to make a request. This service will
/// receive all inbound urls to handle or ignore until another service makes a request.
///
/// This pointer is not proactively freed and just because it points to a service doesn't mean a
/// request is necessairly in flight.
class AuthorizationServiceCurrentRequestStorage {
    static let shared = AuthorizationServiceCurrentRequestStorage()

    weak var currentRequestingService: AuthorizationServiceProtocolInternal?
}

// swiftlint:enable type_name

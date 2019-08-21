//
//  AuthorizationServiceCurrentRequestStorage.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 6/24/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
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

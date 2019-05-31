//
//  StateGenerator.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 5/31/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
import AppAuth

struct StateGenerator {
    static func generate() -> String? {
        return OIDAuthorizationRequest.generateState()
    }
}

enum RequestStateError: Error {
    case generationFailed
}

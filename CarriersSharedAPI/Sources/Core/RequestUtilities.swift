//
//  RequestUtilities.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 5/31/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
import AppAuth

extension String {
    static func generateRequestState() -> String? {
        return OIDAuthorizationRequest.generateState()
    }
}

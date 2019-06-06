//
//  MockOpenIdService.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 5/30/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation
@testable import CarriersSharedAPI

class MockOpenIdService: OpenIdServiceProtocol {

    static let mockSuccess = AuthorizedResponse(code: "abc123", mcc: "123", mnc: "456")
    var lastParameters: OpenIdAuthorizationParameters?
    var lastViewController: UIViewController?
    var mockResponse: OpenIdServiceResult = .code(
        MockOpenIdService.mockSuccess
    )

    func clear() {
        lastParameters = nil
        lastViewController = nil
        mockResponse = .code(
            MockOpenIdService.mockSuccess
        )
    }

    func authorize(
        fromViewController viewController: UIViewController,
        carrierConfig: CarrierConfig,
        authorizationParameters: OpenIdAuthorizationParameters,
        completion: @escaping OpenIdServiceCompletion) {

        self.lastViewController = viewController
        self.lastParameters = authorizationParameters

        DispatchQueue.main.async {
            completion(self.mockResponse)
        }
    }

    var authorizationInProgress: Bool = false

    func cancelCurrentAuthorizationSession() { }

    func resolve(url: URL) -> Bool { return true }

    func concludeAuthorizationFlow(result: AuthorizationResult) { }
}

//
//  ServiceAPI.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

class ServiceAPI: NSObject {

    let session = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: Foundation.OperationQueue.main)
    var dataTask: URLSessionDataTask?

    /// Log in.
    ///
    /// - Parameter code: The auth code returned by by `authorize`.
    /// - Parameter mcc: The mcc returned by by `authorize`
    /// - Parameter mnc: The mnc returned by by `authorize`
    func login(
        withAuthCode code: String,
        mcc: String,
        mnc: String,
        completionHandler tokenResponse: @escaping ((JsonDocument?, Error?) -> Void)) {

        // With the auth code, mcc, and mnc, you have everything you need to re-perform discovery
        // on your secure server and use the discovered token endpoint to request an access token
        // from Project Verify. This access token shouldn't reach the client transparently,
        // but instead be used as the basis for accessing or creating a token within
        // the domain of your application.

        var request = URLRequest(url: URL(string: "https://xci-demoapp-node.raizlabs.xyz/api/auth")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONSerialization.data(withJSONObject: [
            "code": code,
            "mcc": mcc,
            "mnc": mnc,
            ], options: [])

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            guard error == nil, let data = data else {
                tokenResponse(nil, error)
                return
            }

            let json = JsonDocument(data: data)
            tokenResponse(json, nil)
        }

        self.dataTask = dataTask
        dataTask.resume()
    }


    func getUserInfo(with accessToken: String, completionHandler userInfoResponse: @escaping ((JsonDocument) -> Void)) {

        // Once you've successfully exchanged the authorization code for an authorization token
        // on your secure server, you'll be able to access the Project Verify User Info Endpoint.
        // The Project Verify User Info Endpoint shouldn't be accessed from a client but instead
        // should pass information through your server's authenticated endpoints in a way that
        // makes sense for your application.
        //
        // The following code is purely to demonstrate what an authenticated user info endpoint may
        // provide.

        let userInfoJSON: [String: Any] = [
            "sub": "{mcc}{mnc}",
            "name": "Jane Doe",
            "given_name": "Jane",
            "family_name": "Doe",
            "birthdate": "0000-03-22",
            "email": "janedoe@example.com",
            "email_verified": true,
            "address": [
                "street_address": "1234 Hollywood Blvd.\n address line 2",
                "locality": "Los Angeles",
                "region": "CA",
                "postal_code": "90210-3456",
                "country": "US"
            ],
            "postal_code": "90210-3456",
            "phone_number": "+13101234567",
            "phone_number_verified": true
        ]

        DispatchQueue.main.async { userInfoResponse(JsonDocument(object: userInfoJSON)) }
    }
}

// MARK: - Bank App

extension ServiceAPI {
    func completeTransfer(withAuthCode code: String,
                          mcc: String,
                          mnc: String,
                          completionHandler transferResponse: @escaping ((JsonDocument) -> Void)) {


        let transferJSON: [String: Any] = [
            "transferId": "1234",
            "transferState": "complete"
        ]

        DispatchQueue.main.async { transferResponse(JsonDocument(object: transferJSON)) }
    }
}

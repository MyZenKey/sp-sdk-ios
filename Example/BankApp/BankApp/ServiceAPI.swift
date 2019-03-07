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
    /// - Parameter code: The auth code returned by by `connectWithProjectVerify`.
    /// - Parameter mcc: The mcc returned by by `connectWithProjectVerify`
    /// - Parameter mnc: The mnc returned by by `connectWithProjectVerify`
    func login(
        withAuthCode code: String,
        mcc: String,
        mnc: String,
        completionHandler tokenResponse: @escaping ((JsonDocument?, Error?) -> Void)) {

        var request = URLRequest(url: URL(string: "https://xci-demoapp-node.raizlabs.xyz/api/token")!)
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
        //get carrier data
        //        self.carrierConfig = sharedAPI!.discoverCarrierConfiguration()
        //        self.scopes = (carrierConfig!["scopes_supported"] as! String).components(separatedBy: " ")
        //        self.responseTypes = [carrierConfig!["response_types_supported"]! as! String]
        //
        //        var request = URLRequest(url: URL(string: self.carrierConfig!["userinfo_endpoint"] as! String)!)
        //        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        //
        //        let dataTask = session.dataTask(with: request) { (data, response, error) in
        //
        //            let errorJson = JsonDocument(string: "{\"Error\":\(String(describing: error?.localizedDescription))\"}")
        //            guard error == nil else {return userInfoResponse(errorJson)}
        //
        //            if let data = data {
        //                let json = JsonDocument(data: data)
        //                userInfoResponse(json)
        //            }
        //        }
        //        self.dataTask = dataTask
        //        dataTask.resume()
    }
}

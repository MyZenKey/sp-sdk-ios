//
//  ServiceAPI.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

// TODO: refactor w/ new mock SP Service
class ServiceAPI: NSObject {

//    let session = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: Foundation.OperationQueue.main)
//    var dataTask: URLSessionDataTask?
//    var sharedAPI: SharedAPI?
//    var carrierConfig:[String:Any]? = nil
//    var scopes:[String]? = nil
//    var responseTypes:[String]? = nil
//    var clientId:String? = "SocialApp"
//    var secret:String? = "socialapp_client_secret"

//    override init() {
//        //init shared api
//        self.sharedAPI = SharedAPI()
//    }
    
    /// Log in.
    ///
    /// - Parameter code: The code to log in with.
    func login(with code: String, completionHandler tokenResponse: @escaping ((JsonDocument) -> Void)) {
        //get carrier data
//        self.carrierConfig = sharedAPI!.discoverCarrierConfiguration()
//        self.scopes = (carrierConfig!["scopes_supported"] as! String).components(separatedBy: " ")
//        self.responseTypes = [carrierConfig!["response_types_supported"]! as! String]
//
//        // call /token
//
//        var request = URLRequest(url: URL(string: self.carrierConfig!["token_endpoint"] as! String)!)
//        request.httpMethod = "POST"
//        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//        let authorizationCode = "\(self.clientId):\(self.secret)".data(using: .utf8)?.base64EncodedString() ?? ""
//        request.setValue("BASIC \(authorizationCode)", forHTTPHeaderField: "Authorization")
//        //request.httpBody = [].encodeAsUrlParams().data(using: .utf8)
//
//        let dataTask = session.dataTask(with: request) { (data, response, error) in
//
//              guard error == nil else {return}
//
//                if let data = data {
//                let json = JsonDocument(data: data)
//
//                if let accessToken = json["access_token"].toString {
//                    tokenResponse(json)
//                    print(accessToken)
//                } else {
//                    // error, just save json for debug purposes
//                   tokenResponse(json)
//                }
//            }
//        }
//        self.dataTask = dataTask
//        dataTask.resume()
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

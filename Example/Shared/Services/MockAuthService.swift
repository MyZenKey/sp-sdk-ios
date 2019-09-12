//
//  MockAuthService.swift
//  BankApp
//
//  Created by Adam Tierney on 8/27/19.
//  Copyright © 2018 XCI JV, LLC. ALL RIGHTS RESERVED.
//

import UIKit

/// A mock implementation of the service provider API protocol
class MockAuthService: NSObject, ServiceProviderAPIProtocol {
    let session = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: Foundation.OperationQueue.main)
    var dataTask: URLSessionDataTask?

    func login(withAuthCode code: String,
               redirectURI: URL,
               mcc: String,
               mnc: String,
               completion: @escaping (AuthPayload?, Error?) -> Void) {
        DispatchQueue.main.async {
            completion(AuthPayload(token: "my_pretend_auth_token"), nil)
        }
    }

    func login(withUsername username: String,
               password: String,
               completion: @escaping (AuthPayload?, Error?) -> Void) {
        DispatchQueue.main.async {
            completion(AuthPayload(token: "my_pretend_auth_token"), nil)
        }
    }

    func addSecondFactor(withAuthCode code: String,
                         redirectURI: URL,
                         mcc: String,
                         mnc: String,
                         completion: @escaping (AuthPayload?, Error?) -> Void) {
        DispatchQueue.main.async {
            completion(AuthPayload(token: "my_pretend_auth_token"), nil)
        }
    }

    func getUserInfo(completion: @escaping (UserInfo?, Error?) -> Void) {
        let userInfo = UserInfo(
            username: "jane",
            email: "janedoe@rightpoint.com",
            name: "Jane",
            givenName: "Jane",
            familyName: "Doe",
            birthdate: "1/1/1000",
            postalCode: "00000"
        )

        DispatchQueue.main.async {
            completion(userInfo, nil)
        }
    }

    func requestTransfer(withAuthCode code: String,
                         redirectURI: URL,
                         transaction: Transaction,
                         nonce: String,
                         completion: @escaping (Transaction?, Error?) -> Void) {

        DispatchQueue.main.async {
            let completedTransaction = Transaction(time: Date(),
                                                   recipiant: transaction.recipiant,
                                                   amount: transaction.amount)
            var transactions = UserAccountStorage.getTransactionHistory()
            transactions.append(completedTransaction)
            UserAccountStorage.setTransactionHistory(transactions)
            completion(transaction, nil)
        }
    }

    func logout(completion: @escaping (Error?) -> Void) {
        UserAccountStorage.clearUser()
        DispatchQueue.main.async {
            completion(nil)
        }
    }

    func getTransactions(completion: @escaping ([Transaction]?, Error?) -> Void) {
        completion(UserAccountStorage.getTransactionHistory().reversed(), nil)
    }

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
        // from ZenKey. This access token shouldn't reach the client transparently,
        // but instead be used as the basis for accessing or creating a token within
        // the domain of your application.

    }
}

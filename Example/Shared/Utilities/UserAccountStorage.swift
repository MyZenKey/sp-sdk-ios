//
//  UserAccountStorage.swift
//  Example Apps
//
//  Created by Adam Tierney on 6/11/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import Foundation

// NOTE: Never store sensitive credentials in UserDefaults, always use the keychain.
struct UserAccountStorage {
    private static let userNameKey =  "UserAccountStorage.username"
    private static let accountKey =  "UserAccountStorage"
    private static let mccKey =  "UserAccountStorage.mcc"
    private static let mncKey =  "UserAccountStorage.mnc"
    private static let historyKey =  "UserTransactionHistory"

    static func setUser(withAccessToken token: String) {
        UserDefaults.standard.set(token, forKey: accountKey)
    }

    static var mccmnc: (mcc: String, mnc: String)? {
        guard
            let mcc = UserDefaults.standard.string(forKey: mccKey),
            let mnc = UserDefaults.standard.string(forKey: mncKey) else {
                return nil
        }
        return (mcc: mcc, mnc: mnc)
    }

    static func setMCCMNC(mcc: String, mnc: String) {
        UserDefaults.standard.set(mcc, forKey: mccKey)
        UserDefaults.standard.set(mnc, forKey: mncKey)
    }

    static var userName: String? {
        get {
            return UserDefaults.standard.string(forKey: userNameKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userNameKey)
        }
    }

    static func setTransactionHistory(_ transactions: [Transaction]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(transactions) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: historyKey)
        }
    }

    static func getTransactionHistory() -> [Transaction]{
        let defaults = UserDefaults.standard
        if let transactions = defaults.object(forKey: historyKey) as? Data {
            let decoder = JSONDecoder()
            if let loadedTransactions = try? decoder.decode([Transaction].self, from: transactions) {
                return loadedTransactions
            }
        }
        return [Transaction]()
    }

    static var accessToken: String? {
        guard let accessToken: String = UserDefaults.standard.string(forKey: accountKey) else {
            clearUser()
            return nil
        }

        return accessToken
    }

    static func clearUser() {
        UserDefaults.standard.removeObject(forKey: accountKey)
        UserDefaults.standard.removeObject(forKey: mccKey)
        UserDefaults.standard.removeObject(forKey: mncKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
}

// MARK: - Account Storage Mock Helpers

extension UserAccountStorage {
    
    static let mockUserName = "jane"

    static let mockUserInfo = UserInfo(
        username: UserAccountStorage.mockUserName,
        email: "janedoe@rightpoint.com",
        name: "Jane",
        givenName: "Jane",
        familyName: "Doe",
        birthdate: "1/1/1000",
        postalCode: "00000",
        phone: "(212) 555-1234"
    )

    static var isMockUser: Bool {
        return UserAccountStorage.userName == UserAccountStorage.mockUserName
    }
}

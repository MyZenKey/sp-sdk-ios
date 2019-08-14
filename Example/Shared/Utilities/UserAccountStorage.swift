//
//  UserAccountStorage.swift
//  Example Apps
//
//  Created by Adam Tierney on 6/11/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import Foundation

// NOTE: Never store sensetive credentials in UserDefaults, always use the keychain.
struct UserAccountStorage {
    private static let accountKey =  "UserAccountStorage"
    private static let mccKey =  "UserAccountStorage.mcc"
    private static let mncKey =  "UserAccountStorage.mnc"

    static func setUser(withTokenResponse tokenResponse: TokenResponse) {
        do {
            let data = try PropertyListEncoder().encode(tokenResponse)
            UserDefaults.standard.set(data, forKey: accountKey)
        } catch {
            fatalError("invalid login tokens: \(error)")
        }
    }

    static var mccmnc: (mcc: String, mnc: String)? {
        guard
            let mcc = UserDefaults.standard.string(forKey: mccKey),
            let mnc = UserDefaults.standard.string(forKey: mccKey) else {
                return nil
        }
        return (mcc: mcc, mnc: mnc)
    }

    static func setMCCMNC(mcc: String, mnc: String) {
        UserDefaults.standard.set(mcc, forKey: mccKey)
        UserDefaults.standard.set(mnc, forKey: mncKey)
    }

    static var idToken: String? {
        do {
            guard let data: Data = UserDefaults.standard.value(forKey: accountKey) as? Data else {
                clearUser()
                return nil
            }

            let tokenResponse = try PropertyListDecoder().decode(TokenResponse.self, from: data)
            return tokenResponse.idToken
        } catch {
            fatalError("invalid login tokens: \(error)")
        }
    }

    static var accessToken: String? {
        do {
            guard let data: Data = UserDefaults.standard.value(forKey: accountKey) as? Data else {
                clearUser()
                return nil
            }

            let tokenResponse = try PropertyListDecoder().decode(TokenResponse.self, from: data)
            return tokenResponse.accessToken
        } catch {
            fatalError("invalid login tokens: \(error)")
        }
    }

    static func clearUser() {
        UserDefaults.standard.removeObject(forKey: accountKey)
        UserDefaults.standard.removeObject(forKey: mccKey)
        UserDefaults.standard.removeObject(forKey: mncKey)
    }
}

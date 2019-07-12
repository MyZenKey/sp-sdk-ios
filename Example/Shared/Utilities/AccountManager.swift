//
//  AccountManager.swift
//  Example Apps
//
//  Created by Adam Tierney on 6/11/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import Foundation

struct AccountManager {
    private static let accountKey =  "AccountToken"

    static var isLoggedIn: Bool {
        return UserDefaults.standard.value(forKey: accountKey) != nil
    }

    static var token: String? {
        return UserDefaults.standard.string(forKey: accountKey)
    }

    static func login(withToken token: String) {
        UserDefaults.standard.set(token, forKey: accountKey)
    }

    static func logout() {
        UserDefaults.standard.removeObject(forKey: accountKey)
    }
}

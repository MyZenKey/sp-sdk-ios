//
//  URLHandling.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 4/19/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

enum Route: String {
    case authorize = "/authorize"
    case discoveryUI = "/discoveryui"
}

protocol URLHandling {
    func resolve(url: URL) -> Bool
}

protocol RouterServiceProtocol {
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool
}

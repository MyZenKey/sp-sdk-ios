//
//  ProjectVerifyHost.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 4/16/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

//    Issuer –
//    IP - https://100.25.175.177/.well-known/openid_configuration
//    FQDN - https://app.xcijv.com/.well-known/openid_configuration
//    UI –
//    IP – https://23.20.110.44
//    FQDN – https://app.xcijv.com/ui

enum ProjectVerifyHost: String {
    case staging = "https://app.xcijv.com"

    func resource(forPath path: String) -> URL {
        return URL(string: "\(self.rawValue)\(path)")!
    }
}

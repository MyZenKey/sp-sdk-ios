//
//  AppConfig.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import Foundation
import UIKit

class AppConfig {
    static let clientID = ""
    static let clientSecret = ""
    static let consentScope = ""
    static let code_redirect_uri = ""
    static let userInfoURL = ""
    static let AccessTokenURL = ""
    static let AuthorizeURL = ""
    static let searchQuery = ""
    static var UUID : String = "\(UIDevice.current.name)_\(UIDevice.current.localizedModel)_\(UIDevice.current.systemName)_\(UIDevice.current.systemVersion)".data(using: .utf8)?.base64EncodedString() ?? "" // UIDevice.current.identifierForVendor!.uuidString;
}

//
//  PromptValue.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 5/30/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

/// Authorization prompt values.
public enum PromptValue: String {
    /// A Service Provider can ask for a user to authenticate again. (even if the user authenticated
    /// within the last sso authentication period (most carriers this will be 30 min).
    ///
    /// At this time every Service Provider request will trigger an authentication, so the use of
    /// this parameter is redundant.
    case login
    /// An SP can ask for a user to explicitly re-confirm that the user agrees to the exposure of
    /// their data. The MNO will recapture user consent for the listed scopes.
    case consent
}

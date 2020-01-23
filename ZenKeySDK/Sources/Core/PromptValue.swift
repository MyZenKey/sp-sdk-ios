//
//  PromptValue.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 5/30/19.
//  Copyright © 2019 ZenKey, LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
    /// No prompt specified.
    case none
}

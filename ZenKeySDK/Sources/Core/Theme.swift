//
//  Theme.swift
//  ZenKeySDK
//
//  Created by Brenden Peters on 3/20/20.
//  Copyright © 2020 ZenKey, LLC.
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

/// Optional Theme (.light or .dark) to be used for the authorization UX. If included it will override
/// user preference to ensure a coherent, consistent experience with the Service Provider's app
/// design.
public enum Theme: String {
    case dark
    case light
}

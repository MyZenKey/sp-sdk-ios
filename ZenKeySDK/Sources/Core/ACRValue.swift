//
//  ACRValue.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 5/30/19.
//  Copyright © 2019-2020 ZenKey, LLC.
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

/// Authenticator Assurance Values.
///
/// For more informaiton see the [NIST guidelines](https://pages.nist.gov/800-63-3/sp800-63b.html)
public enum ACRValue: String {
    /// AAL1 provides some assurance that the claimant controls an authenticator bound to the
    /// subscriber’s account. AAL1 requires either single-factor or multi-factor authentication
    /// using a wide range of available authentication technologies. Successful authentication
    /// requires that the claimant prove possession and control of the authenticator through a
    /// secure authentication protocol.
    ///
    /// Service Providers should ask for aal1 when they need a low level of authentication, users
    /// will not be asked for their pin or biometrics. Any user holding the device will be able to
    /// authenticate/authorize the transaction unless the user has configured their account to
    /// always require 2nd factor (pin | bio).
    case aal1 = "a1"

    /// AAL2 provides high confidence that the claimant controls an authenticator(s) bound to the
    /// subscriber’s account. Proof of possession and control of two different authentication
    /// factors is required through secure authentication protocol(s). Approved cryptographic
    /// techniques are required at AAL2 and above.
    ///
    /// Authentication of the subscriber SHALL be repeated at least once per 12 hours during an
    /// extended usage session, regardless of user activity. Reauthentication of the subscriber
    /// SHALL be repeated following any period of inactivity lasting 30 minutes or longer. The
    /// session SHALL be terminated (i.e., logged out) when either of these time limits is reached.
    ///
    /// Service Providers should ask for aal2 or aal3 anytime they want to ensure the user has
    /// provided their (pin | bio).
    case aal2 = "a2"

    /// AAL3 provides very high confidence that the claimant controls authenticator(s) bound to the
    /// subscriber’s account. Authentication at AAL3 is based on proof of possession of a key
    /// through a cryptographic protocol. AAL3 authentication requires a hardware-based
    /// authenticator and an authenticator that provides verifier impersonation resistance;
    /// the same device may fulfill both these requirements. In order to authenticate at AAL3,
    /// claimants are required to prove possession and control of two distinct authentication
    /// factors through secure authentication protocol(s). Approved cryptographic techniques are
    /// required.
    ///
    /// Service Providers should ask for aal2 or aal3 anytime they want to ensure the user has
    /// provided their (pin | bio).
    case aal3 = "a3"
}

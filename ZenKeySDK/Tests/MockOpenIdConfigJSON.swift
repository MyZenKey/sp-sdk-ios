//
//  MockOpenIdConfigJSON.swift
//  ZenKeySDK
//
//  Created by Anthony Arthur on 5/27/21.
//  Copyright © 2021 ZenKey, LLC.
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

let mockOpenIDConfigNoProofing = """
{
\"issuer\":\"issuer\", \
\"authorization_endpoint\":\"authorization_endpoint\", \
\"token_endpoint\":\"token_endpoint\", \
\"userinfo_endpoint\":\"userinfo_endpoint\", \
\"jwks_uri\":\"jwks_uri\", \
\"server_initiated_endpoint\":\"server_initiated_endpoint\", \
\"server_initiated_authorization_endpoint\":\"server_initiated_authorization_endpoint\", \
\"server_initiated_cancel_endpoint\":\"server_initiated_cancel_endpoint\", \
\"revocation_endpoint\":\"revocation_endpoint\", \
\"response_types_supported\":[\"async_token\", \"code\"], \
\"subject_types_supported\":[\"pairwise\"], \
\"id_token_signing_alg_values_supported\":[\"RS256\"], \
\"scopes_supported\":[\"name\",\"email\",\"address\",\"phone\",\"openid\",\"postal_code\",\"birthdate\",\"events\"], \
\"mccmnc\":310260, \
\"token_endpoint_auth_methods_supported\":[\"client_secret_basic\",\"client_assertion_jwt\"], \
\"claims_supported\":[\"sub\",\"name\",\"given_name\",\"family_name\",\"email\",\"email_verified\",\"phone_number\",\"address\"], \
\"branding\":\"branding\", \
\"link_branding\":\"link_branding", \
\"link_img\":\"link_img\", \
\"ui_locales_supported\":[\"en-US\"], \
\"registration_endpoint\":\"registration_endpoint\", \
\"grant_types_supported\":[\"authorization_code\"], \
\"acr_values_supported\":[\"a1\",\"a3\"], \
\"service_documentation\":\"service_documentation\", \
\"claims_parameter_supported\":false, \
\"request_parameter_supported\":true, \
\"request_uri_parameter_supported\":false, \
\"op_policy_uri\":\"op_policy_uri\", \
\"usertrait_endpoint\":\"usertrait_endpoint\", \
\"usertraits_supported\":\"usertraits_supported\", \
\"events_supported\":[\"consent_revoked\"], \
\"events_endpoint\":\"events_endpoint\", \
\"user_porting_endpoint\":\"user_porting_endpoint\", \
}
"""

let mockOpenIDConfigWithProofing = """
{
\"issuer\":\"issuer\", \
\"authorization_endpoint\":\"authorization_endpoint\", \
\"token_endpoint\":\"token_endpoint\", \
\"userinfo_endpoint\":\"userinfo_endpoint\", \
\"jwks_uri\":\"jwks_uri\", \
\"server_initiated_endpoint\":\"server_initiated_endpoint\", \
\"server_initiated_authorization_endpoint\":\"server_initiated_authorization_endpoint\", \
\"server_initiated_cancel_endpoint\":\"server_initiated_cancel_endpoint\", \
\"revocation_endpoint\":\"revocation_endpoint\", \
\"response_types_supported\":[\"async_token\", \"code\"], \
\"subject_types_supported\":[\"pairwise\"], \
\"id_token_signing_alg_values_supported\":[\"RS256\"], \
\"scopes_supported\":[\"name\",\"email\",\"address\",\"phone\",\"openid\",\"postal_code\",\"birthdate\",\"events\",\"proofing\"], \
\"mccmnc\":310260, \
\"token_endpoint_auth_methods_supported\":[\"client_secret_basic\",\"client_assertion_jwt\"], \
\"claims_supported\":[\"sub\",\"name\",\"given_name\",\"family_name\",\"email\",\"email_verified\",\"phone_number\",\"address\"], \
\"branding\":\"branding\", \
\"link_branding\":\"link_branding", \
\"link_img\":\"link_img\", \
\"ui_locales_supported\":[\"en-US\"], \
\"registration_endpoint\":\"registration_endpoint\", \
\"grant_types_supported\":[\"authorization_code\"], \
\"acr_values_supported\":[\"a1\",\"a3\"], \
\"service_documentation\":\"service_documentation\", \
\"claims_parameter_supported\":false, \
\"request_parameter_supported\":true, \
\"request_uri_parameter_supported\":false, \
\"op_policy_uri\":\"op_policy_uri\", \
\"usertrait_endpoint\":\"usertrait_endpoint\", \
\"usertraits_supported\":\"usertraits_supported\", \
\"events_supported\":[\"consent_revoked\"], \
\"events_endpoint\":\"events_endpoint\", \
\"user_porting_endpoint\":\"user_porting_endpoint\", \
}
"""

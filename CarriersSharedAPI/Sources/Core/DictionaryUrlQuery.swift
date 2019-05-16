//
//  DictionaryUrlQuery.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL
//  MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT
//  DATED FEBRUARY 7, 2018.
//

import Foundation

extension String {

    /// Returns a url encoded version of self.
    func urlEncode() -> String {
        return addingPercentEncoding(
            withAllowedCharacters: CharacterSet(
                charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
            ) ?? self
    }
}

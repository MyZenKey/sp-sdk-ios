//
//  DictionaryUrlQuery.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import Foundation

extension Dictionary {

    /// Convert a dictionary of URL name/value pairs into a "&" separated string of with correct name/value encodings.
    ///
    /// - Returns: An "&" separated string of encoded parameters
    func encodeAsUrlParams() -> String {
        var parts = [String]()
        for (name, value) in self {
            parts += ["\((name as! String).urlEncode())=\((value as! String).urlEncode())"]
        }
        return parts.joined(separator: "&")
    }
}

extension String {

    /// Returns a url encoded version of self.
    func urlEncode() -> String {
        return addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")) ?? self
    }
}

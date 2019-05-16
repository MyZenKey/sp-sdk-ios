//
//  Constants.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/25/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest
@testable import CarriersSharedAPI

let timeout: TimeInterval = 10.0

struct UnexpectedNilVariableError: Error {}

// swiftlint:disable:next identifier_name
func UnwrapAndAssertNotNil<T>(_ variable: T?,
                              message: String = "Unexpected nil variable",
                              file: StaticString = #file,
                              line: UInt = #line) throws -> T {

    guard let variable = variable else {
        XCTFail(message, file: file, line: line)
        throw UnexpectedNilVariableError()
    }
    return variable
}

struct MockSIMs {
    static let unknown = SIMInfo(mcc: "123", mnc: "456")
    static let tmobile = SIMInfo(mcc: "310", mnc: "210")
    static let att = SIMInfo(mcc: "310", mnc: "410")
}

extension URL {
    static var mocked: URL {
        return URL(string: "rightpoint.com")!
    }
}

extension NSError {
    static var mocked: NSError {
        return NSError(domain: "mockerror", code: 0, userInfo: [:])
    }
}

extension AuthorizationError {
    static var mocked: AuthorizationError {
        return AuthorizationError(rawErrorCode: "mock_error", description: "a mock error")
    }
}

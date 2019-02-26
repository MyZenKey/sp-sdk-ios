//
//  Constants.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 2/25/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import XCTest

let timeout: TimeInterval = 10.0

struct UnexpectedNilVariableError: Error {}

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

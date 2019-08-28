//
//  BankAppUITests.swift
//  BankAppUITests
//
//  Created by Sawyer Billings on 7/22/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import XCTest

class BankAppUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()

        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments.append("--logged-out")
    }

    func testZenKeyButton() {
        app.launch()

        let zenKeyButton = XCUIApplication().buttons["ZenKey Button"]
        XCTAssert(zenKeyButton.exists)
        zenKeyButton.tap()
    }
}

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
    }

    func testProjectVerifyButton() {
        app.launch()

        let projectVerifyButton = XCUIApplication().buttons["Project Verify Button"]
        XCTAssert(projectVerifyButton.exists)
        projectVerifyButton.tap()
    }
}

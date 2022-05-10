//
//  bassiTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/8/22.
//

import XCTest
@testable import bassi

class bassiTests: XCTestCase {
  func testExample() throws {
    let program = "10 REM Comment"
    let interpreter = Interpreter(Parse.skip)
    let output = interpreter.run(program)
    XCTAssertEqual(output, "")
  }
}

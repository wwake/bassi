//
//  bassiTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/8/22.
//

import XCTest
@testable import bassi

class BassiTests: XCTestCase {
  func test10REM() throws {
    let program = "10 REM Comment"
    let interpreter = Bassi(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "")
  }

  func xtest20PRINT() {
    let program = "20 PRINT"
    let interpreter = Bassi(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "\n")
  }
}

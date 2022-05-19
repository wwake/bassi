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
    let program = Program("10 REM Comment")
    let interpreter = Bassi(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "")
  }

  func test20PRINT() {
    let program = Program("20 PRINT")
    let interpreter = Bassi(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "\n")
  }

  func test25PRINT42() {
    let program = Program("25 PRINT 42")
    let interpreter = Bassi(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "42\n")
  }

  func testPowers() {
    let program = Program("25 PRINT 2^3^2")
    let interpreter = Bassi(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "64\n")
  }

  func testLogicalOperationsOnIntegers() {
    let program = Program("25 PRINT NOT -8 OR 5 AND 4")
    let interpreter = Bassi(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "7\n")
  }
}

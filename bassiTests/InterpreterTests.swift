//
//  InterpreterTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/9/22.
//

import XCTest
@testable import bassi

class InterpreterTests: XCTestCase {

  func testSkip() throws {
    let parse = Parse.program([
      Parse.line(Token.integer(10), Parse.skip)
    ])

    let interpreter = Interpreter(parse)
    let output = interpreter.run()
    XCTAssertEqual(output, "")
  }

  func testPrint() throws {
    let parse = Parse.program([
      Parse.line(Token.integer(10), Parse.print([]))
    ])

    let interpreter = Interpreter(parse)
    let output = interpreter.run()
    XCTAssertEqual(output, "\n")
  }
}

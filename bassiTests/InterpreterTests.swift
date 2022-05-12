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

  func testSimplePrint() throws {
    let parse = Parse.program([
      Parse.line(Token.integer(10), Parse.print([]))
    ])

    let interpreter = Interpreter(parse)
    let output = interpreter.run()
    XCTAssertEqual(output, "\n")
  }

  func testPrintWithValue() {
    let parse = Parse.program([
      .line(
        .integer(35),
        .print([.number(.integer(22))]))
    ])

    let interpreter = Interpreter(parse)
    let output = interpreter.run()
    XCTAssertEqual(output, "22 \n")
  }

  func testPrintWithAddition() {
    let parse = Parse.program([
      .line(
        .integer(40),
        .print([
          .op2(
            .plus,
            .op2(
              .plus,
              .number(.integer(1)),
              .number(.integer(2))),
            .number(.integer(3)))
        ]))
    ])

    let interpreter = Interpreter(parse)
    let output = interpreter.run()
    XCTAssertEqual(output, "6 \n")
  }
}

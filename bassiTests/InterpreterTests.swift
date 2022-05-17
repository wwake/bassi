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
      Parse.line(10, Parse.skip)
    ])

    let interpreter = Interpreter(parse)
    let output = interpreter.run()
    XCTAssertEqual(output, "")
  }

  func testSimplePrint() throws {
    let parse = Parse.program([
      Parse.line(10, Parse.print([]))
    ])

    let interpreter = Interpreter(parse)
    let output = interpreter.run()
    XCTAssertEqual(output, "\n")
  }

  func testPrintWithValue() {
    let parse = Parse.program([
      .line(
        35,
        .print([.number(22.0)]))
    ])

    let interpreter = Interpreter(parse)
    let output = interpreter.run()
    XCTAssertEqual(output, "22\n")
  }

  func testPrintWithUnaryMinus() {
    let expr = Expression.op1(
      .minus,
      .number(21.0))
    let interpreter = Interpreter(.skip)
    let output = interpreter.evaluate(expr)
    XCTAssertEqual(output, -21)
  }

  func testPrintWithAddition() {
    let parse = Parse.program([
      .line(
        40,
        .print([
          Expression.make(1, .plus, 2, .plus, 3)
        ]))
    ])

    let interpreter = Interpreter(parse)
    let output = interpreter.run()
    XCTAssertEqual(output, "6\n")
  }

  func testPrintWithSubtraction() {
    let parse = Parse.program([
      .line(
        40,
        .print([
          Expression.make(1, .minus, 2, .minus, 3)
        ]))
    ])

    let interpreter = Interpreter(parse)
    let output = interpreter.run()
    XCTAssertEqual(output, "-4\n")
  }

  func testPrintWithMultiplyDivide() {
    let parse = Parse.program([
      .line(
        40,
        .print([
          Expression.make(1, .times, 6, .divide, 3)
        ]))
    ])

    let interpreter = Interpreter(parse)
    let output = interpreter.run()
    XCTAssertEqual(output, "2\n")
  }

  func testPrintWithEqualityComparison() {
    let parse = Parse.program([
      .line(
        40,
        .print([
          Expression.make(10, .equals, 10)
        ]))
    ])

    let interpreter = Interpreter(parse)
    let output = interpreter.run()
    XCTAssertEqual(output, "1\n")
  }

}

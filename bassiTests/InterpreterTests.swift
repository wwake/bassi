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

    let interpreter = Interpreter(Program())

    let output = interpreter.interpret(parse, "")
    XCTAssertEqual(output, "")
  }

  func testSimplePrint() throws {
    let parse = Parse.program([
      Parse.line(10, Parse.print([]))
    ])

    let interpreter = Interpreter(Program())
    let output = interpreter.interpret(parse, "")
    XCTAssertEqual(output, "\n")
  }

  func testPrintWithValue() {
    let parse = Parse.program([
      .line(
        35,
        .print([.number(22.0)]))
    ])

    let interpreter = Interpreter(Program())
    let output = interpreter.interpret(parse, "")
    XCTAssertEqual(output, "22\n")
  }

  func testLogicalOperationsOnIntegers() {
    // NOT -8 OR 5 AND 4
    // 11111..1000  -8
    // 0000....111  7 = NOT -8
    // 0.......101  5
    // 0.......100  4
    // ===>    111  = 7

    let expression = Expression.op2(
      .or,
      .op1(.not,
           .op1(.minus, .number(8))),
      .op2(
        .and,
        .number(5),
        .number(4)
      )
    )

    let parse = Parse.program([
      .line(
        40,
        .print([expression]))
    ])

    let interpreter = Interpreter(Program())
    let output = interpreter.interpret(parse, "")
    XCTAssertEqual(output, "7\n")
  }

  func testPrintWithUnaryMinus() {
    let expr = Expression.op1(
      .minus,
      .number(21.0))
    let interpreter = Interpreter(Program())
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

    let interpreter = Interpreter(Program())
    let output = interpreter.interpret(parse, "")
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

    let interpreter = Interpreter(Program())
    let output = interpreter.interpret(parse, "")
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

    let interpreter = Interpreter(Program())
    let output = interpreter.interpret(parse, "")
    XCTAssertEqual(output, "2\n")
  }

  fileprivate func checkPrintWithRelop(_ op: Token, _ expected: Int) {
    let parse = Parse.program([
      .line(
        40,
        .print([
          Expression.make(10, op, 10)
        ]))
    ])

    let interpreter = Interpreter(Program())
    let output = interpreter.interpret(parse, "")
    XCTAssertEqual(output, "\(expected)\n")
  }

  fileprivate func checkRelop(
    _ op1ExpectedTrue: Token,
    _ op2ExpectedFalse: Token) {
      checkPrintWithRelop(op1ExpectedTrue, 1)
      checkPrintWithRelop(op2ExpectedFalse, 0)
  }

  func testPrintWithEqualityComparison() {
    checkRelop(.equals, .notEqual)
    checkRelop(.greaterThanOrEqualTo, .lessThan)
    checkRelop(.lessThanOrEqualTo, .greaterThan)
  }

  func test10Goto10() {
    let parse = Parse.program([
      .line(
        10,
        .goto(10))
    ])

    let interpreter = Interpreter(Program())

    XCTAssertEqual(interpreter.lineNumber, 0)

    let _ = interpreter.interpret(parse, "")

    XCTAssertEqual(interpreter.lineNumber, 10)
  }

  func testStepWillEvenGotoMissingLine() {
    let parse = Parse.program([
      .line(
        10,
        .goto(20))
    ])

    let interpreter = Interpreter(Program())

    let _ = interpreter.interpret(parse, "")

    XCTAssertEqual(interpreter.lineNumber, 20)
  }
}

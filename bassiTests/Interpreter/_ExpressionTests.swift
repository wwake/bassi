//
//  _ExpressionTests.swift
//  bassiTests
//
//  Created by Bill Wake on 7/4/22.
//

import XCTest
@testable import bassi

class _ExpressionTests: InterpreterTests {

  func testPowers() {
    checkProgramResults(
      "25 PRINT 2^3^2",
      expecting: " 64 \n")
  }

  func testLogicalOperationsOnIntegersTree() throws {
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

    let parse =
    Parse(
      40,
      [.print([.expr(expression), .newline])])

    let outputter = Interactor()
    let interpreter = Interpreter(Program(), outputter)
    try interpreter.step(parse.statements[0])
    XCTAssertEqual(outputter.output, " 7 \n")
  }

  func testLogicalOperationsOnIntegers() throws {
    checkProgramResults(
      "25 PRINT NOT -8 OR 5 AND 4",
      expecting: " 7 \n")
  }

  func testVariableDefaultsToZero() throws {
    checkProgramResults(
      "25 PRINT Y9",
      expecting: " 0 \n")
  }

  func testEvaluateExpressionWithUnaryMinus() throws {
    let expr = Expression.op1(
      .minus,
      .number(21.0))
    let outputter = Interactor()
    let interpreter = Interpreter(Program(), outputter)
    let output = try interpreter.evaluate(expr, [:])
    XCTAssertEqual(output, .number(-21))
  }

  func testAddition() throws {
    checkProgramResults("40 PRINT 1+2+3", expecting: " 6 \n")
  }

  func testSubtraction() throws {
    checkProgramResults("40 PRINT 1-2-3", expecting: "-4 \n")
  }

  func testMultiplyDivide() throws {
    checkProgramResults("40 PRINT 1*6/3", expecting: " 2 \n")
  }

  func testEqualityComparison() throws {
    try checkOppositeRelationalOps("=", "<>")
    try checkOppositeRelationalOps(">=", "<")
    try checkOppositeRelationalOps("<=", ">")
  }

  func testAssignment() throws {
    checkProgramResults("""
10 X = 42
25 PRINT X
""",
                        expecting: " 42 \n")
  }

  func testStringRelationalOperator() {
    checkProgramResults(
      "25 PRINT \"A\"<\"B\"",
      expecting: " 1 \n")
  }

  func testStringVariableDefaultsToEmptyString() {
    checkProgramResults(
      "25 PRINT A$",
      expecting: "\n")
  }
}

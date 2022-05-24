//
//  ParserTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/10/22.
//

import XCTest
@testable import bassi

class ParserTests: XCTestCase {

  func checkExpression(
    _ expression: String,
    _ expected: Expression) {

      let input = "10 PRINT \(expression)"
      let parser = Parser()
      let result = parser.parse(input)
      XCTAssertEqual(
        result,
        .line(
          10,
          .print([expected]))
      )
      XCTAssertEqual(parser.errorMessages, [])
    }

  func checkError(_ program: String, _ expected: ParseError) {
    let line = program
    let parser = Parser()
    _ = parser.parse(line)
    XCTAssertEqual(
      parser.errors(),
      [expected])
  }

  func test10END() throws {
    let line = "10 END"
    let parser = Parser()
    let result = parser.parse(line)
    XCTAssertEqual(
      result,
      .line(10, .end))
  }

  func test10REM() throws {
    let line = "10 REM whatever"
    let parser = Parser()

    let result = parser.parse(line)
    XCTAssertEqual(
      result,
      .line(10, .skip)
    )
  }

  func testNoLineNumber() {
    checkError(
      "REM remark",
      .noLineNumber)
  }

  func testPrintStatement() {
    let line = "25 PRINT"
    let parser = Parser()
    let result = parser.parse(line)
    XCTAssertEqual(
      result,
      .line(25, .print([]))
    )
  }

  func testPrintStatementWithNumber() {
    let line = "25 PRINT 42"
    let parser = Parser()
    let result = parser.parse(line)
    XCTAssertEqual(
      result,
      .line(
        25,
        .print([.number(42.0)]))
    )
  }

  func testPrintPrintIsError() {
    checkError(
      "25 PRINT PRINT",
      .expectedStartOfExpression
    )
  }

  func testGoto() throws {
    let line = "10 GOTO 10"
    let parser = Parser()
    let result = parser.parse(line)
    XCTAssertEqual(
      result,
      .line(
        10,
        .goto(10))
    )
  }

  func testGotoWithMissingTarget() throws {
    checkError(
      "10 GOTO",
      .missingTarget
    )
  }

  func testOrExpr() throws {
    checkExpression(
      "2 OR 4 AND 5",
      .op2(
        .or,
        .number(2),
        .op2(
          .and,
          .number(4),
          .number(5)))
    )
  }

  func testAndExpr() throws {
    checkExpression(
      "2 < 3 AND 4",
      Expression.make(2, .lessThan, 3, .and, 4)
    )
  }
  
  func testRelationalHasPrecedenceOverNegation() throws {
    checkExpression(
      "NOT 2 < 3",
      Expression.make(.not, 2, .lessThan, 3)
    )
  }

  func checkRelational(_ relation: String, _ token: Token) throws {
    checkExpression(
      "1" + relation + "2",
      Expression.make(1, token, 2)
    )
  }

  func testRelationalComparison() throws {
    try checkRelational("=", .equals)
    try checkRelational("<", .lessThan)
    try checkRelational("<=", .lessThanOrEqualTo)
    try checkRelational("<>", .notEqual)
    try checkRelational(">", .greaterThan)
    try checkRelational(">=", .greaterThanOrEqualTo)
  }

  func testSimpleAddition() throws {
    checkExpression(
      "1+2",
      Expression.make(1, .plus, 2)
    )
  }

  func testAdditionIsLeftAssociative() throws {
    checkExpression(
      "1+2+3",
      Expression.make(1, .plus, 2, .plus, 3))
  }

  func testSubtraction() throws {
    checkExpression(
      "1-2-3",
      Expression.make(1, .minus, 2, .minus, 3)
    )
  }

  func testMultiplyDivide() throws {
    checkExpression(
      "1*6/3",
      Expression.make(1, .times, 6, .divide, 3)
    )
  }

  func testPowerIsLeftAssociative() throws {
    checkExpression(
      "2^3^4",
      Expression.make(2, .exponent, 3, .exponent, 4)
    )
  }

  func testUnaryMinusHasPrecedenceOverPower() throws {
    checkExpression(
      "-2^3",
      Expression.make(.minus, 2, .exponent, 3)
    )
  }

  func testParenthesizedExpression() throws {
    checkExpression(
      "((21))",
      .number(21.0)
    )
  }

  func testMissingRightParentheses() {

    let expression = "(((21)"
    checkError(
      "10 PRINT \(expression)",
      .missingRightParend
    )
  }

  func testPrintImproperExpression() {
    checkError(
      "10 PRINT +",
      .expectedStartOfExpression
    )
  }
  func testErrorWhenFactorIsNotValid() {
    let expression = "(((*"
    checkError(
      "10 PRINT \(expression)",
      .expectedStartOfExpression
    )
  }

  func testUnaryMinus() throws {
    checkExpression (
      "---21",
      .op1(.minus,
           .op1(.minus,
                .op1(.minus,
                     .number(21.0))))
    )
  }

  func testVariable() throws {
    checkExpression(
      "X",
      .variable("X"))
  }

  func testIfThenLineNumber() throws {
    let line = "42 IF 0 THEN 43"
    let parser = Parser()
    let result = parser.parse(line)
    XCTAssertEqual(
      result,
      .line(
        42,
        .`if`(.number(0), 43))
    )
    XCTAssertEqual(parser.errorMessages, [])
  }

  func testIfMissingThenGetsError() throws {
    checkError(
      "42 IF 0 PRINT",
      .missingTHEN
    )
  }

  func testIfThenMissingTargetGetsError() throws {
    checkError(
      "42 IF 0 THEN",
      .missingTarget
    )
  }

  func testAssignmentStatementWithNumber() {
    let line = "25 X = 42"
    let parser = Parser()
    let result = parser.parse(line)
    XCTAssertEqual(
      result,
      .line(
        25,
        .assign(
          "X",
          .number(42.0)))
    )
  }

  func testAssignmentStatementWithLET() {
    let line = "25 LET A = 2"
    let parser = Parser()
    let result = parser.parse(line)
    XCTAssertEqual(
      result,
      .line(
        25,
        .assign(
          "A",
          .number(2.0)))
    )
  }

  func testAssignMissingEqualSign() {
    checkError(
      "42 HUH REMARK",
      .assignmentMissingEqualSign
    )
  }

  func testLETMissingAssignment() {
    checkError(
      "42 LET",
      ParseError.letMissingAssignment
    )
  }
}

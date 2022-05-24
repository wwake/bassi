//
//  ParserTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/10/22.
//

import XCTest
@testable import bassi

class ParserTests: XCTestCase {

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
    let line = "REM remark"
    let parser = Parser()
    _ = parser.parse(line)
    XCTAssertEqual(
      parser.errors(),
      [ParseError.noLineNumber])
  }

  func testUnknownStatement() {
    let line = "42 HUH REMARK"
    let parser = Parser()
    _ = parser.parse(line)
    XCTAssertEqual(
      parser.errors(),
      [
        ParseError.unknownStatement
      ])
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
    let line = "25 PRINT PRINT"
    let parser = Parser()
    let _ = parser.parse(line)

    XCTAssertEqual(parser.errorMessages, [ParseError.extraCharactersAtEol])
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
    let line = "10 GOTO"
    let parser = Parser()
    let _ = parser.parse(line)
    XCTAssertEqual(parser.errorMessages, [ParseError.missingTarget])
  }

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
    let input = "10 PRINT \(expression)"
    let parser = Parser()
    let _ = parser.parse(input)
    XCTAssertEqual(parser.errorMessages, [ParseError.missingRightParend])
  }

  func testPrintImproperExpression() {
    let input = "10 PRINT +"
    let parser = Parser()
    let _ = parser.parse(input)
    XCTAssertEqual(parser.errorMessages, [ParseError.expectedStartOfExpression])

  }
  func testErrorWhenFactorIsNotValid() {
    let expression = "(((*"
    let input = "10 PRINT \(expression)"
    let parser = Parser()
    let _ = parser.parse(input)
    XCTAssertEqual(parser.errorMessages, [ParseError.expectedStartOfExpression])
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
    let line = "42 IF 0 PRINT"
    let parser = Parser()
    let _ = parser.parse(line)
    XCTAssertEqual(parser.errorMessages, [ParseError.missingTHEN])
  }

  func testIfThenMissingTargetGetsError() throws {
    let line = "42 IF 0 THEN"
    let parser = Parser()
    let _ = parser.parse(line)
    XCTAssertEqual(parser.errorMessages, [ParseError.missingTarget])
  }
}

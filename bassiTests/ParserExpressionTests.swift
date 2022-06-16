//
//  ParserExpressionTests.swift
//  bassiTests
//
//  Created by Bill Wake on 6/14/22.
//

import XCTest
@testable import bassi

class ParserExpressionTests: XCTestCase {
  func checkExpression(
    _ expression: String,
    _ expected: Expression) {

      let input = "10 PRINT \(expression)"
      let parser = Parser()
      let result = parser.parse(input)
      XCTAssertEqual(
        result,
        Parse(
          10,
          [.print([expected])])
      )
    }

  func checkRelational(_ relation: String, _ token: TokenType) throws {
    checkExpression(
      "1" + relation + "2",
      Expression.make(1, token, 2)
    )
  }

  func checkError(
    _ program: String,
    _ expected: ParseError)
  {
    let line = program
    let parser = Parser()
    let output = parser.parse(line)
    XCTAssertEqual(
      output,
      Parse(output.lineNumber, [.error(expected)]))
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
      .error("Missing ')'")
    )
  }

  func testPrintImproperExpression() {
    checkError(
      "10 PRINT +",
      .error("Expected start of expression")
    )
  }
  func testErrorWhenFactorIsNotValid() {
    let expression = "(((*"
    checkError(
      "10 PRINT \(expression)",
      .error("Expected start of expression")
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
      .variable("X", .number))
  }

  func testRelationalOperatorNeedsSameTypes() {
    checkError("17 A=B$ < 3", .error("Type mismatch"))
    checkError("17 A=33=B$", .error("Type mismatch"))
  }


}

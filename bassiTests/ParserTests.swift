//
//  ParserTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/10/22.
//

import XCTest
@testable import bassi

extension Parser {
  func expression(_ testInput: String) throws -> Expression {
    lexer = Lexer(testInput)
    nextToken()
    return try expression()
  }
}

class ParserTests: XCTestCase {
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

  func testOrExpr() throws {
    let expression = "2 OR 4 AND 5"
    let parser = Parser()
    let result = try parser.expression(expression)
    XCTAssertEqual(
      result,
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
    let expression = "2 < 3 AND 4"
    let parser = Parser()
    let result = try parser.expression(expression)
    XCTAssertEqual(
      result,
      Expression.make(2, .lessThan, 3, .and, 4)
    )
  }
  
  func testRelationalHasPrecedenceOverNegation() throws {
    let expression = "NOT 2 < 3"
    let parser = Parser()
    let result = try parser.expression(expression)
    XCTAssertEqual(
      result,
      Expression.make(.not, 2, .lessThan, 3)
    )
  }

  func checkRelational(_ relation: String, _ token: Token) throws {
    let expression = "1" + relation + "2"
    let parser = Parser()
    let result = try parser.expression(expression)
    XCTAssertEqual(
      result,
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
    let expression = "1+2"
    let parser = Parser()
    let result = try parser.expression(expression)
    XCTAssertEqual(
      result,
      Expression.make(1, .plus, 2)
    )
  }

  func testAdditionIsLeftAssociative() throws {
    let expression = "1+2+3"
    let parser = Parser()
    let result = try parser.expression(expression)
    XCTAssertEqual(
      result,
      Expression.make(1, .plus, 2, .plus, 3))
  }

  func testSubtraction() throws {
    let expression = "1-2-3"
    let parser = Parser()
    let result = try parser.expression(expression)
    XCTAssertEqual(
      result,
      Expression.make(1, .minus, 2, .minus, 3)
    )
  }

  func testMultiplyDivide() throws {
    let expression = "1*6/3"
    let parser = Parser()
    let result = try parser.expression(expression)
    XCTAssertEqual(
      result,
      Expression.make(1, .times, 6, .divide, 3)
    )
  }

  func testPowerIsLeftAssociative() throws {
    let expression = "2^3^4"
    let parser = Parser()
    let result = try parser.expression(expression)
    XCTAssertEqual(
      result,
      Expression.make(2, .exponent, 3, .exponent, 4)
    )
  }

  func testUnaryMinusHasPrecedenceOverPower() throws {
    let expression = "-2^3"
    let parser = Parser()
    let result = try parser.expression(expression)
    XCTAssertEqual(
      result,
      Expression.make(.minus, 2, .exponent, 3)
    )
  }

  func testParenthesizedExpression() throws {
    let expression = "((21))"
    let parser = Parser()
    let result = try parser.expression(expression)
    XCTAssertEqual(
      result,
      .number(21.0)
    )
  }

  func testMissingRightParentheses() {
    do {
      let expression = "(((21)"
      let parser = Parser()
      _ = try parser.expression(expression)
      XCTFail("exception should have been thrown")
    } catch ParseError.missingRightParend {
      // ok
    } catch {
      XCTFail("wrong exception thrown: " + error.localizedDescription)
    }
  }

  func testErrorWhenFactorIsNotValid() {
    do {
      let expression = "(((*"
      let parser = Parser()
      _ = try parser.expression(expression)
      XCTFail("exception should have been thrown")
    } catch ParseError.expectedNumberOrLeftParend {
      // ok
    } catch {
      XCTFail("wrong exception thrown: " + error.localizedDescription)
    }
  }

  func testUnaryMinus() throws {
    let expression = "---21"
    let parser = Parser()
    let result = try parser.expression(expression)
    XCTAssertEqual(
      result,
      .op1(.minus,
           .op1(.minus,
                .op1(.minus,
                     .number(21.0))))
    )
  }
}

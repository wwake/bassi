//
//  ParserTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/10/22.
//

import XCTest
@testable import bassi

class ParserTests: XCTestCase {
  func test10REM() throws {
    let program = "10 REM whatever"
    let parser = Parser(Lexer(program))

    let result = parser.parse()
    XCTAssertEqual(
      result,
      .program([
        .line(10, .skip)
      ]))
  }

  func testNoLineNumber() {
    let program = "REM remark"
    let parser = Parser(Lexer(program))
    _ = parser.parse()
    XCTAssertEqual(
      parser.errors(),
      [ParseError.noLineNumber])
  }

  func testUnknownStatement() {
    let program = "42 HUH REMARK"
    let parser = Parser(Lexer(program))
    _ = parser.parse()
    XCTAssertEqual(
      parser.errors(),
      [
        ParseError.unknownStatement
      ])
  }

  func testPrintStatement() {
    let program = "25 PRINT"
    let parser = Parser(Lexer(program))
    let result = parser.parse()
    XCTAssertEqual(
      result,
      .program([
        .line(25, .print([]))
      ]))
  }

  func testPrintStatementWithNumber() {
    let program = "25 PRINT 42"
    let parser = Parser(Lexer(program))
    let result = parser.parse()
    XCTAssertEqual(
      result,
      .program([
        .line(
          25,
          .print([.number(42.0)]))
      ]))
  }

  func testPrintPrintIsError() {
    let program = "25 PRINT PRINT"
    let parser = Parser(Lexer(program))
    let _ = parser.parse()

    XCTAssertEqual(parser.errorMessages, [ParseError.extraCharactersAtEol])
  }

  func testMultiLine() throws {
    let program = """
10 PRINT
20 PRINT 42
"""
    let parser = Parser(Lexer(program))
    let result = parser.parse()
    XCTAssertEqual(
      result,
      .program([
        .line(
          10,
          .print([])),
        .line(
          20,
          .print([.number(42.0)]))
      ]))
  }

  func testGoto() throws {
    let program = "10 GOTO 10"
    let parser = Parser(Lexer(program))
    let result = parser.program()
    XCTAssertEqual(
      result,
      .program([
        .line(
          10,
          .goto(10))
      ]))
  }

  func testOrExpr() throws {
    let program = "2 OR 4 AND 5"
    let parser = Parser(Lexer(program))
    let result = try parser.expression()
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
    let program = "2 < 3 AND 4"
    let parser = Parser(Lexer(program))
    let result = try parser.expression()
    XCTAssertEqual(
      result,
      Expression.make(2, .lessThan, 3, .and, 4)
    )
  }
  
  func testRelationalHasPrecedenceOverNegation() throws {
    let program = "NOT 2 < 3"
    let parser = Parser(Lexer(program))
    let result = try parser.expression()
    XCTAssertEqual(
      result,
      Expression.make(.not, 2, .lessThan, 3)
    )
  }

  func checkRelational(_ relation: String, _ token: Token) throws {
    let program = "1" + relation + "2"
    let parser = Parser(Lexer(program))
    let result = try parser.expression()
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
    let program = "1+2"
    let parser = Parser(Lexer(program))
    let result = try parser.expression()
    XCTAssertEqual(
      result,
      Expression.make(1, .plus, 2)
    )
  }

  func testAdditionIsLeftAssociative() throws {
    let program = "1+2+3"
    let parser = Parser(Lexer(program))
    let result = try parser.expression()
    XCTAssertEqual(
      result,
      Expression.make(1, .plus, 2, .plus, 3))
  }

  func testSubtraction() throws {
    let program = "1-2-3"
    let parser = Parser(Lexer(program))
    let result = try parser.expression()
    XCTAssertEqual(
      result,
      Expression.make(1, .minus, 2, .minus, 3)
    )
  }

  func testMultiplyDivide() throws {
    let program = "1*6/3"
    let parser = Parser(Lexer(program))
    let result = try parser.expression()
    XCTAssertEqual(
      result,
      Expression.make(1, .times, 6, .divide, 3)
    )
  }

  func testPowerIsLeftAssociative() throws {
    let program = "2^3^4"
    let parser = Parser(Lexer(program))
    let result = try parser.expression()
    XCTAssertEqual(
      result,
      Expression.make(2, .exponent, 3, .exponent, 4)
    )
  }

  func testUnaryMinusHasPrecedenceOverPower() throws {
    let program = "-2^3"
    let parser = Parser(Lexer(program))
    let result = try parser.expression()
    XCTAssertEqual(
      result,
      Expression.make(.minus, 2, .exponent, 3)
    )
  }

  func testParenthesizedExpression() throws {
    let program = "((21))"
    let parser = Parser(Lexer(program))
    let result = try parser.expression()
    XCTAssertEqual(
      result,
      .number(21.0)
    )
  }

  func testMissingRightParentheses() {
    do {
      let program = "(((21)"
      let parser = Parser(Lexer(program))
      _ = try parser.expression()
      XCTFail("exception should have been thrown")
    } catch ParseError.missingRightParend {
      // ok
    } catch {
      XCTFail("wrong exception thrown: " + error.localizedDescription)
    }
  }

  func testErrorWhenFactorIsNotValid() {
    do {
      let program = "(((*"
      let parser = Parser(Lexer(program))
      _ = try parser.expression()
      XCTFail("exception should have been thrown")
    } catch ParseError.expectedNumberOrLeftParend {
      // ok
    } catch {
      XCTFail("wrong exception thrown: " + error.localizedDescription)
    }
  }

  func testUnaryMinus() throws {
    let program = "---21"
    let parser = Parser(Lexer(program))
    let result = try parser.expression()
    XCTAssertEqual(
      result,
      .op1(.minus,
           .op1(.minus,
                .op1(.minus,
                     .number(21.0))))
    )
  }
}

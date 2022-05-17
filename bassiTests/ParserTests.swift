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

  func testEqualityComparison() throws {
    let program = "1=2"
    let parser = Parser(Lexer(program))
    let result = try parser.expression()
    XCTAssertEqual(
      result,
      Expression.make(1, .equals, 2)
    )
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

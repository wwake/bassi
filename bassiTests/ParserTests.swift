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
        .line(.integer(10), .skip)
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
        .line(.integer(25), .print([]))
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
          .integer(25),
          .print([.number(.integer(42))]))
      ]))
  }

  func testParenthesizedExpression() throws {
    let program = "((21))"
    let parser = Parser(Lexer(program))
    let result = try parser.expression()
    XCTAssertEqual(
      result,
      .number(.integer(21))
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
      XCTFail("wrong exception thrown")
    }
  }

  func testSimpleAddition() throws {
    let program = "1+2"
    let parser = Parser(Lexer(program))
    let result = try parser.expression()
    XCTAssertEqual(
      result,
      .op2(
        .plus,
        .number(.integer(1)),
        .number(.integer(2)))
    )
  }

  func testAdditionIsLeftAssociative() throws {
    let program = "1+2+3"
    let parser = Parser(Lexer(program))
    let result = try parser.expression()
    XCTAssertEqual(
      result,
      .op2(
        .plus,
        .op2(
          .plus,
          .number(.integer(1)),
          .number(.integer(2))),
        .number(.integer(3)))
    )
  }
}

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
      Parse.program([
        Parse.line(Token.line(10), Parse.skip)
      ]))
  }

  func testNoLineNumber() {
    let program = "REM remark"
    let parser = Parser(Lexer(program))
    let result = parser.parse()
    XCTAssertEqual(
      result,
      Parse.program([
        Parse.error("no line number")
      ]))
  }

  func testUnknownStatement() {
    let program = "42 HUH REMARK"
    let parser = Parser(Lexer(program))
    let result = parser.parse()
    XCTAssertEqual(
      result,
      Parse.program([
        Parse.line(
          Token.line(42),
          Parse.error("unknown statement"))
      ]))
  }

}

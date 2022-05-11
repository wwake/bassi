//
//  ScannerTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/9/22.
//

import Foundation
import XCTest
@testable import bassi

class LexerTests: XCTestCase {

  func checkToken(_ program: String, _ expected: Token) {
    let lexer = Lexer(program)
    let token = lexer.next()
    XCTAssertEqual(token, expected)
  }

  func testAtEnd() {
    checkToken("", Token.atEnd)
  }

  func testLineNumber() throws {
    checkToken("10  REM Comment", Token.integer(10))
  }

  func testLineNumberLeadingSpaces() {
    checkToken("  11 REM ", Token.integer(11))
  }

  func testLineNumberInternalSpaces() {
    checkToken(" 1 2 REM ", Token.integer(12))
  }

  func testRemark() throws {
    checkToken("REM Comment", Token.remark)
  }

  func testTwoRemarks() {
    let lexer = Lexer("10 REM #\n20 REM")
    var token = lexer.next()
    XCTAssertEqual(token, Token.integer(10))

    token = lexer.next()
    XCTAssertEqual(token, Token.remark)

    token = lexer.next()
    XCTAssertEqual(token, Token.integer(20))

    token = lexer.next()
    XCTAssertEqual(token, Token.remark)

    token = lexer.next()
    XCTAssertEqual(token, Token.atEnd)
  }

  func testUnexpectedStatement() {
    checkToken("WHAT", Token.error("unrecognized name"))
  }

  func testUnexpectedCharacters() {
    checkToken("😬", Token.error("not yet implemented"))
  }

  func testPRINT() throws {
    checkToken("PRINT", Token.print)
  }
}

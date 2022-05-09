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

  func testLineNumber() throws {
    checkToken("10  REM Comment", Token.line(10))
  }

  func testLineNumberLeadingSpaces() {
    checkToken("  11 REM ", Token.line(11))
  }

  func testLineNumberInternalSpaces() {
    checkToken(" 1 2 REM ", Token.line(12))
  }

  func testRemark() throws {
    checkToken("REM Comment", Token.remark)
  }

  func testTwoRemarks() {
    let lexer = Lexer("10 REM #\n20 REM")
    var token = lexer.next()
    XCTAssertEqual(token, Token.line(10))

    token = lexer.next()
    XCTAssertEqual(token, Token.remark)

    token = lexer.next()
    XCTAssertEqual(token, Token.line(20))

    token = lexer.next()
    XCTAssertEqual(token, Token.remark)

    token = lexer.next()
    XCTAssertEqual(token, Token.atEnd)
  }

  func testAtEnd() {
    checkToken("", Token.atEnd)
  }
}

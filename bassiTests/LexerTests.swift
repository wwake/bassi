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

  func checkLineNumber(_ program: String, _ expected: Int) {
    let lexer = Lexer(program)
    let token1 = lexer.next()
    XCTAssertEqual(token1, Token.line(expected))
  }

  func testLineNumber() throws {
    checkLineNumber("10  REM Comment", 10)
  }

  func testLineNumberLeadingSpaces() {
    checkLineNumber("  11 REM ", 11)
  }

  func testLineNumberInternalSpaces() {
    checkLineNumber(" 1 2 REM ", 12)
  }

  func testRemark() throws {
    let program = "REM Comment"
    let lexer = Lexer(program)
    let token1 = lexer.next()
    XCTAssertEqual(token1,  Token.remark)
  }

  func testAtEnd() {
    let program = ""
    let lexer = Lexer(program)
    let token1 = lexer.next()
    XCTAssertEqual(token1,  Token.atEnd)
  }
}

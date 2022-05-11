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
    checkToken("", .atEnd)
  }

  func testInteger() throws {
    checkToken("10  REM Comment", .integer(10))
  }

  func testLineNumberLeadingSpaces() {
    checkToken("  11 REM ", .integer(11))
  }

  func testLineNumberInternalSpaces() {
    checkToken(" 1 2 REM ", .integer(12))
  }

  func testRemark() throws {
    checkToken("REM Comment", .remark)
  }

  func testTwoRemarks() {
    let lexer = Lexer("10 REM #\n20 REM")
    var token = lexer.next()
    XCTAssertEqual(token, .integer(10))

    token = lexer.next()
    XCTAssertEqual(token, .remark)

    token = lexer.next()
    XCTAssertEqual(token, .integer(20))

    token = lexer.next()
    XCTAssertEqual(token, .remark)

    token = lexer.next()
    XCTAssertEqual(token, .atEnd)
  }

  func testUnexpectedStatement() {
    checkToken("WHAT", .error("unrecognized name"))
  }

  func testUnexpectedCharacters() {
    checkToken("😬", .error("not yet implemented"))
  }

  func testPRINT() throws {
    checkToken("PRINT", .print)
  }

  func testPRINTthenNumber() {
    let lexer = Lexer("25 PRINT 42")
    var token = lexer.next()
    XCTAssertEqual(token, .integer(25))

    token = lexer.next()
    XCTAssertEqual(token, .print)

    token = lexer.next()
    XCTAssertEqual(token, .integer(42))

    token = lexer.next()
    XCTAssertEqual(token, .atEnd)
  }

  func testSingleCharacterOperators() throws {
    checkToken("+", .plus)
    checkToken("-", .minus)
    checkToken("*", .times)
    checkToken("/", .divide)
    checkToken("^", .exponent)
    checkToken("=", .equals)
  }
}

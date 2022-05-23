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
    let lexer = Lexer("")
    
    let token1 = lexer.next()
    XCTAssertEqual(token1, .eol)

    let token2 = lexer.next()
    XCTAssertEqual(token2, .atEnd)
  }

  func testAtEol() {
    checkToken("\n", .eol)
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

  func testFirstTokenAlwaysExpectsInteger() {
    checkToken("1END", .integer(1))
  }

  func testNumbersPastLineNumberExpectFloat() {
    let lexer = Lexer("10 PRINT 20")

    var token = lexer.next()
    XCTAssertEqual(token, .integer(10))

    token = lexer.next()
    XCTAssertEqual(token, .print)

    token = lexer.next()
    XCTAssertEqual(token, .number(20))
  }

  func testRemark() throws {
    checkToken("REM Comment", .remark)
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

  func testPRINTaNumber() {
    let lexer = Lexer("25 PRINT 42")
    var token = lexer.next()
    XCTAssertEqual(token, .integer(25))

    token = lexer.next()
    XCTAssertEqual(token, .print)

    token = lexer.next()
    XCTAssertEqual(token, .number(42))

    token = lexer.next()
    XCTAssertEqual(token, .eol)

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
    checkToken("(", .leftParend)
    checkToken(")", .rightParend)
  }

  func testRelationalOperators() {
    checkToken("<", .lessThan)
    checkToken("<=", .lessThanOrEqualTo)
    checkToken("<>", .notEqual)
    checkToken(">", .greaterThan)
    checkToken(">=", .greaterThanOrEqualTo)
  }

  func checkNumber(_ input: String, _ expected: Token) {
    let lexer = Lexer("10 PRINT \(input)")

    var token = lexer.next()
    XCTAssertEqual(token, .integer(10))

    token = lexer.next()
    XCTAssertEqual(token, .print)

    token = lexer.next()
    XCTAssertEqual(token, expected)
  }

  func testNumberLexing() {
    checkNumber("14", .number(14))
    checkNumber("14.5", .number(14.5))
    checkNumber("14.5E1", .number(145))
    checkNumber("17.5e1", .number(175))
    checkNumber("14.", .number(14))
  }

  func testNumberErrors() {
    let lexer = Lexer("10 PRINT 14.3E")

    var token = lexer.next()
    XCTAssertEqual(token, .integer(10))

    token = lexer.next()
    XCTAssertEqual(token, .print)

    token = lexer.next()
    XCTAssertEqual(token, .error("Exponent value is missing"))
  }

  func testThenFollowedByDigitGetsInteger() {
    let lexer = Lexer("20 THEN 9")

    let token1 = lexer.next()
    XCTAssertEqual(token1, .integer(20))

    let token2 = lexer.next()
    XCTAssertEqual(token2, .then)

    let token3 = lexer.next()
    XCTAssertEqual(token3, .integer(9))
  }

  func testThenFollowedByPrintDigitGetsNumber() {
    let lexer = Lexer("20THENPRINT9")

    let token1 = lexer.next()
    XCTAssertEqual(token1, .integer(20))

    let token2 = lexer.next()
    XCTAssertEqual(token2, .then)

    let token3 = lexer.next()
    XCTAssertEqual(token3, .print)

    let token4 = lexer.next()
    XCTAssertEqual(token4, .number(9))

  }
}

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

  func checkToken(_ program: String, _ expected: TokenType) {
    let lexer = Lexer(program)
    let token = lexer.next()
    XCTAssertEqual(token.type, expected)
  }

  func checkString(_ item: String, _ expectedType: TokenType, _ expectedString: String) {
    let lexer = Lexer("10 PRINT \(item)")

    var token = lexer.next()
    token = lexer.next()

    token = lexer.next()
    XCTAssertEqual(token.type, expectedType)
    XCTAssertEqual(token.string, expectedString)

    token = lexer.next()
  }

  func checkUnquotedString(_ item: String, _ expectedType: TokenType, _ expectedString: String) {
    let lexer = Lexer("10 DATA \(item)")

    var token = lexer.next()
    token = lexer.next()

    token = lexer.next()
    XCTAssertEqual(token.type, expectedType)
    XCTAssertEqual(token.string, expectedString)

    token = lexer.next()
  }

  func testAtEnd() {
    let lexer = Lexer("")
    
    let token1 = lexer.next()
    XCTAssertEqual(token1.type, .eol)

    let token2 = lexer.next()
    XCTAssertEqual(token2.type, .atEnd)
  }

  func testAtEol() {
    checkToken("\n", .eol)
  }

  func testTokenKnowsLineNumber() {
    let lexer = Lexer("10 PRINT")
    let token1 = lexer.next()
    XCTAssertEqual(token1.line, 10)

    let token2 = lexer.next()
    XCTAssertEqual(token2.line, 10)
  }

  func testFirstIntegerOnLineIsTreatedAsLineNumber() {
    let lexer = Lexer("PRINT 10")
    let token1 = lexer.next()
    XCTAssertEqual(token1.line, 0)

    let token2 = lexer.next()
    XCTAssertEqual(token2.line, 10)
  }

  func testTokenDefaultLineNumberIsZero() {
    let lexer = Lexer("PRINT")
    let token = lexer.next()
    XCTAssertEqual(token.line, 0)
  }

  func testTokenColumnIsTrackedAgainstNormalizedLine() {
    let lexer = Lexer("1  0  PR INT 40")
    let token1 = lexer.next()
    XCTAssertEqual(token1.column, 0)

    let token2 = lexer.next()
    XCTAssertEqual(token2.column, 2)

    let token3 = lexer.next()
    XCTAssertEqual(token3.column, 7)
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

  func testNumbersPastLineNumberMayStillBeIntegers() {
    let lexer = Lexer("10 PRINT 20")

    var token = lexer.next()
    XCTAssertEqual(token.type, .integer(10))

    token = lexer.next()
    XCTAssertEqual(token.type, .print)

    token = lexer.next()
    XCTAssertEqual(token.type, .integer(20))
  }

  func testRemark() throws {
    checkToken("REM Comment", .remark)
  }

  func testUnexpectedCharacters() {
    checkToken("😬", .error("unexpected character"))
  }

  func testPRINT() throws {
    checkToken("PRINT", .print)
  }

  func testPRINTaNumber() {
    let lexer = Lexer("25 PRINT 42")
    var token = lexer.next()
    XCTAssertEqual(token.type, .integer(25))

    token = lexer.next()
    XCTAssertEqual(token.type, .print)

    token = lexer.next()
    XCTAssertEqual(token.type, .integer(42))

    token = lexer.next()
    XCTAssertEqual(token.type, .eol)

    token = lexer.next()
    XCTAssertEqual(token.type, .atEnd)
  }

  func testStringKnowsItsContents() {
    checkString("\"body\"", .string, "body")
  }

  func testEmptyStringKnowsItsContents() {
    checkString("\"\"", .string, "")
  }

  func testUnterminatedStringIsAnError() {
    checkString("\"body", .error("unterminated string"), "unterminated string")
  }

  func testStringsMayContainBlanks() {
    checkString(
      "\"HEllO world\"",
      .string, "HEllO world")
  }

  func testNonStringsAreUppercased() {
    checkToken("prINt", .print)
  }

  func testUnquotedString() {
    checkUnquotedString("X", .string, "X")
  }

  func testUnquotedStringGetTrimmedAndUppercased() {
    checkUnquotedString(" dog  ", .string, "DOG")
  }

  func testUnquotedStringCanMatchNumbers() {
    checkUnquotedString(" 42  ", .string, "42")
  }

  func testUnquotedStringStopsAfterColon() {
    let lexer = Lexer("10 DATA DOG: 20 PRINT X")

    var token = lexer.next()
    token = lexer.next()

    token = lexer.next()
    XCTAssertEqual(token.type, .string)
    XCTAssertEqual(token.string, "DOG")

    token = lexer.next()
    XCTAssertEqual(token.type, .colon)

    token = lexer.next()
    XCTAssertEqual(token.type, .integer(20))
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
    checkToken(",", .comma)
  }

  func testRelationalOperators() {
    checkToken("<", .lessThan)
    checkToken("<=", .lessThanOrEqualTo)
    checkToken("<>", .notEqual)
    checkToken(">", .greaterThan)
    checkToken(">=", .greaterThanOrEqualTo)
  }


  func checkNumber(_ input: String, _ expected: TokenType) {
    let lexer = Lexer("10 PRINT \(input)")

    var token = lexer.next()
    XCTAssertEqual(token.type, .integer(10))

    token = lexer.next()
    XCTAssertEqual(token.type, .print)

    token = lexer.next()
    XCTAssertEqual(token.type, expected)
  }

  func testNumberLexing() {
    checkNumber("14", .integer(14))
    checkNumber("14.5", .number(14.5))
    checkNumber("14.5E1", .number(145))
    checkNumber("17.5e1", .number(175))
    checkNumber("14.", .number(14))
  }

  func testNumberErrors() {
    let lexer = Lexer("10 PRINT 14.3E")

    var token = lexer.next()
    XCTAssertEqual(token.type, .integer(10))

    token = lexer.next()
    XCTAssertEqual(token.type, .print)

    token = lexer.next()
    XCTAssertEqual(token.type, .error("Exponent value is missing"))
  }

  func testThenFollowedByDigitGetsInteger() {
    let lexer = Lexer("20 THEN 9")

    let token1 = lexer.next()
    XCTAssertEqual(token1.type, .integer(20))

    let token2 = lexer.next()
    XCTAssertEqual(token2.type, .then)

    let token3 = lexer.next()
    XCTAssertEqual(token3.type, .integer(9))
  }

  func testThenFollowedByPrintDigitGetsInteger() {
    let lexer = Lexer("20THENPRINT9")

    let token1 = lexer.next()
    XCTAssertEqual(token1.type, .integer(20))

    let token2 = lexer.next()
    XCTAssertEqual(token2.type, .then)

    let token3 = lexer.next()
    XCTAssertEqual(token3.type, .print)

    let token4 = lexer.next()
    XCTAssertEqual(token4.type, .integer(9))
  }

  func testVariableWithSingleLetter() {
    let lexer = Lexer("A")

    let token1 = lexer.next()

    XCTAssertEqual(token1.type, .variable("A"))
  }

  func testVariableWithLetterPlusDigit() {
    let lexer = Lexer("Z9")

    let token1 = lexer.next()

    XCTAssertEqual(token1.type, .variable("Z9"))
  }

  func testVariableWithLetterPlusDigitPlusDollar() {
    let lexer = Lexer("M0$")

    let token1 = lexer.next()

    XCTAssertEqual(token1.type, .variable("M0$"))
  }

  func testReservedWordFn() {
    checkToken("FNA(X)", TokenType.fn)
  }

  func testFunctionCallWithSqr() {
    checkToken("SQR(4)", TokenType.predefined("SQR", `Type`.typeNtoN))
  }

  func testFunctionNameWithDollarSign() {
    checkToken("LEFT$(", TokenType.predefined("LEFT$", `Type`.typeSNtoS))
  }
}

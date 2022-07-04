//
//  PrintTests.swift
//  bassiTests
//
//  Created by Bill Wake on 7/4/22.
//

import XCTest
@testable import bassi

class PrintTests : InterpreterTests {
  func testPRINTaddsNewlineByDefault() {
    checkProgramResults(
      "20 PRINT",
      expecting: "\n")
  }

  func testPRINTwithSemicolonSuppressesNewline() {
    checkProgramResults(
      "25 PRINT;",
      expecting: "")
  }

  func testPRINTnumericValue() {
    checkProgramResults(
      "25 PRINT 42",
      expecting: " 42 \n")
  }

  func testPRINTwithMultipleExpressions() {
    checkProgramResults("25 PRINT \"X=\" X", expecting: "X= 0 \n")
  }

  func testPRINTwithCommas() {
    checkProgramResults(
      "50 PRINT 1,27.125,\"str\"",
      expecting: " 1           27.125000  str\n")
  }

  func testPRINTwithTab() {
    checkProgramResults(
      "20 PRINT \"X\" TAB(5) \"Y\";",
      expecting: "X    Y")
  }

  func testPRINTwithTabToEarlierColumn() {
    checkProgramResults(
      "20 PRINT \"XYZ\" TAB(2) \"Y\";",
      expecting: "XYZ\n  Y")
  }

  func testPrintWithStringValue() throws {
    checkProgramResults(
      "35 PRINT \"hello\"",
      expecting: "hello\n")
  }

  func testMultiplePRINTonOneLine() {
    checkProgramResults(
      "35 PRINT 135: PRINT 136",
      expecting: " 135 \n 136 \n")
  }

  func testPrintIntegerUsesNoDecimals() {
    checkProgramResults(
      "1 PRINT 42",
      expecting: " 42 \n")
  }

  func testPrintIntegerValueDropsDecimalPoint() throws {
    checkProgramResults(
      "35 PRINT 22.0",
      expecting: " 22 \n")
  }

  func testPrintFloatDoesUseDecimals() {
    checkProgramResults(
      "1 PRINT 0.875000",
      expecting: " 0.875000 \n")
  }

}


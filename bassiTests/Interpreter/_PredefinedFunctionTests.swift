//
//  _PredefinedFunctionTests.swift
//  bassiTests
//
//  Created by Bill Wake on 7/4/22.
//

import XCTest
@testable import bassi

class PredefinedFunctionTests: InterpreterTests {
  func testCallSqr() {
    checkProgramResults(
      "25 PRINT SQR(4)",
      expecting: " 2 \n")
  }

  func testCallSin() {
    checkProgramResults(
      "25 PRINT SIN(0)",
      expecting: " 0 \n")
  }

  func testCallLen() {
    checkProgramResults(
      "25 PRINT LEN(\"ABC\")",
      expecting: " 3 \n")
  }

  func testTypeDefaultValueForFunctionIs0() {
    XCTAssertEqual(
      Type.function([.number], .number).defaultValue(),
      Value.string("?? Undefined function"))
  }

  func testNumericSystemFunctions() {
    checkProgramResults(
      "1 PRINT ABS(-1)",
      expecting: " 1 \n")

    checkProgramResults(
      "1 PRINT ATN(1)",
      expecting: " 0.785398 \n")

    checkProgramResults(
      "1 PRINT COS(1)",
      expecting: " 0.540302 \n")

    checkProgramResults(
      "1 PRINT EXP(1)",
      expecting: " 2.718282 \n")

    checkProgramResults(
      "1 PRINT FRE(1)",
      expecting: " 100000 \n")

    checkProgramResults(
      "1 PRINT INT(41.99)",
      expecting: " 41 \n")

    checkProgramResults(
      "1 PRINT LOG(2.71)",
      expecting: " 0.996949 \n")

    checkProgramResults(
      "1 PRINT SGN(-41.99)",
      expecting: "-1 \n")

    checkProgramResults(
      "1 PRINT SIN(1.56)",
      expecting: " 0.999942 \n")

    checkProgramResults(
      "1 PRINT SQR(64)",
      expecting: " 8 \n")

    checkProgramResults(
      "1 PRINT TAN(3.14)",
      expecting: "-0.001593 \n")
  }

  func testRandomNumbersAreInProperRange() throws {
    try (1...1000).forEach { _ in
      let outputter = Interactor()
      let interpreter = Interpreter(Program("1 PRINT RND(0)"), outputter)
      try interpreter.run()
      let value = Float(outputter.output.trimmingCharacters(in: .whitespacesAndNewlines))!
      XCTAssertTrue(value >= 0 && value < 1)
    }
  }

  func testDefaultSeed0StartsDifferentEachTime() throws {
    var lastValue: Float = 0
    try (1...100).forEach { _ in
      let outputter = Interactor()
      let interpreter = Interpreter(Program("1 PRINT RND(0)"), outputter)
      try interpreter.run()
      let value = Float(outputter.output.trimmingCharacters(in: .whitespacesAndNewlines))!
      XCTAssertNotEqual(lastValue, value)
      lastValue = value
    }
  }

  func testSeedsForceIdenticalSequences() throws {
    let outputter = Interactor()
    let program =
"""
10 FOR I=1 TO 10: PRINT RND(42);: NEXT I
20 PRINT
30 FOR I=1 TO 10: PRINT RND(17);: NEXT I
40 PRINT
50 FOR I=1 TO 10: PRINT RND(42);: NEXT I
60 PRINT
70 FOR I=1 TO 10: PRINT RND(17);: NEXT I
80 PRINT
"""
    let interpreter = Interpreter(Program(program), outputter)
    try interpreter.run()
    let lines = outputter.output.split(separator:"\n")
    XCTAssertEqual(lines[0], lines[2])
    XCTAssertEqual(lines[1], lines[3])
  }

  func testStringSystemFunctions() {
    checkProgramResults(
      "1 PRINT LEN(\"ABCDE\")",
      expecting: " 5 \n")

    checkProgramResults(
      "1 PRINT CHR$(42)",
      expecting: "*\n")

    checkProgramResults(
      "1 PRINT STR$(-21)",
      expecting: "-21 \n")
  }

  func testASCfunction() {
    checkProgramResults(
      "1 PRINT ASC(\"DAD\")",
      expecting: " 68 \n")

    checkProgramResults(
      "1 PRINT ASC(\"\")",
      expecting: " 0 \n")
  }

  func testLEFTfunction() {
    checkProgramResults(
      "1 PRINT LEFT$(\"ABC\", 2)",
      expecting: "AB\n")

    checkProgramResults(
      "1 PRINT LEFT$(\"\", 10)",
      expecting: "\n")

    checkProgramResults(
      "1 PRINT LEFT$(\"ABC\", 0)",
      expecting: "\n")

    checkProgramResults(
      "1 PRINT LEFT$(\"ABC\", 10)",
      expecting: "ABC\n")
  }

  func testRIGHTfunction() {
    checkProgramResults(
      "1 PRINT RIGHT$(\"ABC\", 2)",
      expecting: "BC\n")

    checkProgramResults(
      "1 PRINT RIGHT$(\"\", 10)",
      expecting: "\n")

    checkProgramResults(
      "1 PRINT RIGHT$(\"ABC\", 0)",
      expecting: "\n")

    checkProgramResults(
      "1 PRINT RIGHT$(\"ABC\", 10)",
      expecting: "ABC\n")
  }

  func testMIDfunctionWith3Arguments() {
    checkProgramResults(
      "1 PRINT MID$(\"ABCDE\", 2, 3)",
      expecting: "BCD\n")

    checkProgramResults(
      "1 PRINT MID$(\"\", 1, 2)",
      expecting: "\n")

    checkProgramResults(
      "1 PRINT MID$(\"ABC\", 2, 0)",
      expecting: "\n")
  }

  func testMIDfunctionWith2Arguments() {
    checkProgramResults(
      "1 PRINT MID$(\"ABCDE\", 2)",
      expecting: "BCDE\n")

    checkProgramResults(
      "1 PRINT MID$(\"\", 1)",
      expecting: "\n")
  }

  func testVALfunction() {
    checkProgramResults(
      "1 PRINT VAL(\"21.25\")",
      expecting: " 21.250000 \n")

    checkProgramResults(
      "1 PRINT VAL(\"junk\")",
      expecting: " 0 \n")
  }
}

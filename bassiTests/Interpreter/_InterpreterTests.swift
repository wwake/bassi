//
//  InterpreterTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/9/22.
//

import XCTest
@testable import bassi

class InterpreterTests: XCTestCase {
   func checkProgramResults(_ program: String, expecting: String) {
    do {
      let interactor = Interactor()
      let interpreter = Interpreter(Program(program), interactor)
      try interpreter.run()
      XCTAssertEqual(interactor.output, expecting)
    } catch {
      XCTFail("\(error)")
    }
  }

  func checkProgramResultsWithInput(_ program: String, input: String, expecting: String) {
    do {
      let interactor = Interactor()
      interactor.input = input

      let interpreter = Interpreter(Program(program), interactor)
      try interpreter.run()

      XCTAssertEqual(interactor.output, expecting)
    } catch {
      XCTFail("\(error)")
    }
  }

  func checkExpectedError(_ program: String, expecting: String) {
    do {
      let interactor = Interactor()

      let interpreter = Interpreter(Program(program), interactor)
      let _ = try interpreter.run()
      XCTFail("Should have thrown error")
    } catch InterpreterError.error(_, let message){
      XCTAssertEqual(message, expecting)
    } catch {
      XCTFail("Unexpected error \(error)")
    }
  }

  func checkPrintWithRelop(_ op: String, _ expected: Int) throws {
    let program = "40 PRINT 10 \(op) 10"
    checkProgramResults(program, expecting: " \(expected) \n")
  }

  func checkOppositeRelationalOps(
    _ op1ExpectedTrue: String,
    _ op2ExpectedFalse: String) throws {
      try checkPrintWithRelop(op1ExpectedTrue, 1)
      try checkPrintWithRelop(op2ExpectedFalse, 0)
    }

  func testEnd() throws {
    let program = Program("999 END")
    let outputter = Interactor()
    let interpreter = Interpreter(program, outputter)
    let _ = try interpreter.run()
    XCTAssertTrue(interpreter.done)
  }

  func testEndThrowsErrorIfAnyActiveSubroutines() throws {
    let program =
"""
10 GOSUB 20
20 X=1
"""

    checkExpectedError(
      program,
      expecting: "Ended program without returning from active subroutine")
  }

  func testSyntaxErrorStopsInterpreter() throws {
    let program = "10 PRINT {}"
    let outputter = Interactor()
    let interpreter = Interpreter(Program(program), outputter)
    try interpreter.run()
    XCTAssertTrue(outputter.output.starts(with:"?10:7 Expected start of expression"), "was \(outputter.output)")
  }

  func testRemainingPartsOfLineDontExecuteIfControlTransfered() {
    checkProgramResults(
"""
10 GOTO 20: PRINT 10
20 PRINT 20
""", expecting: " 20 \n")
  }

  func test10Goto10() throws {
    let parse =
    Parse(
      10,
      [.goto(10)])

    let outputter = Interactor()
    let interpreter = Interpreter(Program("10 GOTO 10"), outputter)

    XCTAssertEqual(interpreter.nextLocation, nil)

    let _ = try interpreter.step(parse.statements[0])

    XCTAssertEqual(interpreter.nextLocation, Location(10,0))
  }

  func testStepWillTryToGotoMissingLine() throws {
    let parse =
    Parse(
      10,
      [.goto(20)])

    let outputter = Interactor()
    let interpreter = Interpreter(Program(), outputter)

    let _ = try interpreter.step(parse.statements[0])

    XCTAssertEqual(interpreter.nextLocation, Location(20,0))
  }

  func testGotoNonExistentLine() {
    checkProgramResults(
      "10 GOTO 20",
      expecting: "? Attempted to execute non-existent line: 20\n")
  }

  func testTwoLineProgramRunsBothLines() throws {
    checkProgramResults("""
25 PRINT 25
40 END
""",
                        expecting: " 25 \n")
  }

  func testRunMultiLineProgramAndFallOffTheEnd() throws {
    checkProgramResults("""
25 GOTO 50
30 PRINT 30
50 PRINT 50
""",
                        expecting: " 50 \n")
  }

  func ifWithFalseResultFallsThrough() throws {
    checkProgramResults("""
25 IF 0 THEN 50
30 PRINT 30
50 PRINT 50
""",
                        expecting: " 30 \n 50 \n")
  }

  func testIfWithTrueResultDoesGoto() throws {
    checkProgramResults("""
25 IF 1 THEN 50
30 PRINT 30
50 PRINT 50
""",
                        expecting: " 50 \n")
  }

  func testIfWithStatementRunsWhenTrue() throws {
    checkProgramResults("""
25 IF 1 THEN PRINT 25
50 PRINT 50
""",
                        expecting: " 25 \n 50 \n")
  }

  func testIfWithMultipleStatements() throws {
    checkProgramResults("""
25 IF 1 THEN PRINT 25: PRINT 30
50 PRINT 50
""",
                        expecting: " 25 \n 30 \n 50 \n")
  }

  func testIfWithMultipleStatementsAndFailingCondition() throws {
    checkProgramResults("""
25 IF 0 THEN PRINT 25: PRINT 30
50 PRINT 50
""",
                        expecting: " 50 \n")
  }

  func testAssignment() throws {
    checkProgramResults("""
10 X = 42
25 PRINT X
""",
                        expecting: " 42 \n")
  }

  func testStringRelationalOperator() {
    checkProgramResults(
      "25 PRINT \"A\"<\"B\"",
      expecting: " 1 \n")
  }

  func testStringVariableDefaultsToEmptyString() {
    checkProgramResults(
      "25 PRINT A$",
      expecting: "\n")
  }

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

  func testDictionaryIsReallyCopyOnWrite() {
    let globals = ["A": "Apple", "B": "Ball"]
    var locals = globals
    locals["B"] = "Boat"

    XCTAssertEqual(locals["A"], "Apple")
    XCTAssertEqual(locals["B"], "Boat")

    XCTAssertEqual(globals["A"], "Apple")
    XCTAssertEqual(globals["B"], "Ball")
  }

  func testDEFstoresItsFunctionForLater() throws {
    let parse =
    Parse(
      40,
      [.def(
        "FNI",
        "X",
        .variable("X", .number),
        .string
      )])

    let outputter = Interactor()
    let interpreter = Interpreter(Program(), outputter)
    let _ = try interpreter.step(parse.statements[0])
    XCTAssertNotNil(interpreter.globals["FNI"])
  }

  func testDEFcantRedefineFunction() {
    checkExpectedError(
      "10 DEF FNA(X)=X\n20 DEF FNA(Y)=42",
      expecting: "Can't redefine function FNA")
  }

  func testCallUserDefinedFunction() {
    checkProgramResults("""
10 DEF FNI(X)=X
25 PRINT FNI(3)
""",
                        expecting: " 3 \n")
  }

  func testUsingStaticScope() {
    checkProgramResults("""
10 DEF FNA(Y)= Y + FNB(Y+1)
20 DEF FNB(X)= X+Y
30 Y=1
40 PRINT FNA(3)
""",
                        expecting: " 8 \n")
  }

  func testCallOnUndefinedFunctionFails() {
    checkExpectedError(
      "10 PRINT FNX(0)",
      expecting: "Attempted call on undefined function FNX")
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


  func testErrorMessageIncludesLineNumber() throws {
    do {
      let program = "20 PRINT A(-2)"
      let outputter = Interactor()
      let interpreter = Interpreter(Program(program), outputter)
      let _ = try interpreter.run()
      XCTFail("Should have thrown error")
    } catch InterpreterError.error(let lineNumber, _) {
      XCTAssertEqual(lineNumber, 20)
    }
  }
}

//
//  InterpreterTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/9/22.
//

import XCTest
@testable import bassi

class InterpreterTests: XCTestCase {

  fileprivate func checkProgramResults(_ program: String, expecting: String) {
    let interpreter = Interpreter(Program(program))
    let output = interpreter.run()
    XCTAssertEqual(output, expecting)
  }

  fileprivate func checkPrintWithRelop(_ op: Token, _ expected: Int) {
    let parse =
    Parse.line(
      40,
      .print([
        Expression.make(10, op, 10)
      ]))

    let interpreter = Interpreter(Program())
    let output = interpreter.step(parse, "")
    XCTAssertEqual(output, "\(expected)\n")
  }

  fileprivate func checkRelop(
    _ op1ExpectedTrue: Token,
    _ op2ExpectedFalse: Token) {
      checkPrintWithRelop(op1ExpectedTrue, 1)
      checkPrintWithRelop(op2ExpectedFalse, 0)
    }

  func test10REM() throws {
    checkProgramResults(
      "10 REM Comment",
      expecting: "")
  }

  func test20PRINT() {
    checkProgramResults(
      "20 PRINT",
      expecting: "\n")
  }

  func test25PRINT42() {
    checkProgramResults(
      "25 PRINT 42",
      expecting: "42\n")
  }

  func testEnd() {
    let program = Program("999 END")
    let interpreter = Interpreter(program)
    let _ = interpreter.run()
    XCTAssertTrue(interpreter.done)
  }

  func testSkip() throws {
    let parse = Parse.line(10, Parse.skip)

    let interpreter = Interpreter(Program())

    let output = interpreter.step(parse, "")
    XCTAssertEqual(output, "")
  }

  func testSimplePrint() throws {
    let parse =
    Parse.line(10, Parse.print([]))

    let interpreter = Interpreter(Program())
    let output = interpreter.step(parse, "")
    XCTAssertEqual(output, "\n")
  }

  func testPrintWithNumericValue() {
    let parse =
    Parse.line(
      35,
      .print([.number(22.0)]))

    let interpreter = Interpreter(Program())
    let output = interpreter.step(parse, "")
    XCTAssertEqual(output, "22\n")
  }

  func testPrintWithStringValue() {
    let parse =
    Parse.line(
      35,
      .print([.string("hello")]))

    let interpreter = Interpreter(Program())
    let output = interpreter.step(parse, "")
    XCTAssertEqual(output, "hello\n")
  }

  func testPowers() {
    checkProgramResults(
      "25 PRINT 2^3^2",
      expecting: "64\n")
  }

  func testLogicalOperationsOnIntegersTree() {
    // NOT -8 OR 5 AND 4
    // 11111..1000  -8
    // 0000....111  7 = NOT -8
    // 0.......101  5
    // 0.......100  4
    // ===>    111  = 7

    let expression = Expression.op2(
      .or,
      .op1(.not,
           .op1(.minus, .number(8))),
      .op2(
        .and,
        .number(5),
        .number(4)
      )
    )

    let parse =
    Parse.line(
      40,
      .print([expression]))

    let interpreter = Interpreter(Program())
    let output = interpreter.step(parse, "")
    XCTAssertEqual(output, "7\n")
  }

  func testLogicalOperationsOnIntegers() {
    let program = Program("25 PRINT NOT -8 OR 5 AND 4")
    let interpreter = Interpreter(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "7\n")
  }

  func testVariableDefaultsToZero() {
    let program = Program("25 PRINT Y9")
    let interpreter = Interpreter(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "0\n")
  }

  func testPrintWithUnaryMinus() {
    let expr = Expression.op1(
      .minus,
      .number(21.0))
    let interpreter = Interpreter(Program())
    let output = interpreter.evaluate(expr, [:])
    XCTAssertEqual(output, .number(-21))
  }

  func testPrintWithAddition() {
    let parse =
    Parse.line(
      40,
      .print([
        Expression.make(1, .plus, 2, .plus, 3)
      ])
    )
    
    let interpreter = Interpreter(Program())
    let output = interpreter.step(parse, "")
    XCTAssertEqual(output, "6\n")
  }

  func testPrintWithSubtraction() {
    let parse =
    Parse.line(
      40,
      .print([
        Expression.make(1, .minus, 2, .minus, 3)
      ]))

    let interpreter = Interpreter(Program())
    let output = interpreter.step(parse, "")
    XCTAssertEqual(output, "-4\n")
  }

  func testPrintWithMultiplyDivide() {
    let parse =
    Parse.line(
      40,
      .print([
        Expression.make(1, .times, 6, .divide, 3)
      ]))

    let interpreter = Interpreter(Program())
    let output = interpreter.step(parse, "")
    XCTAssertEqual(output, "2\n")
  }

  func testPrintWithEqualityComparison() {
    checkRelop(.equals, .notEqual)
    checkRelop(.greaterThanOrEqualTo, .lessThan)
    checkRelop(.lessThanOrEqualTo, .greaterThan)
  }

  func test10Goto10() {
    let parse =
    Parse.line(
      10,
      .goto(10))

    let interpreter = Interpreter(Program("10 GOTO 10"))

    XCTAssertEqual(interpreter.lineNumber, 10)

    let _ = interpreter.step(parse, "")

    XCTAssertEqual(interpreter.lineNumber, 10)
  }

  func testStepWillEvenGotoMissingLine() {
    let parse =
    Parse.line(
      10,
      .goto(20))

    let interpreter = Interpreter(Program())

    let _ = interpreter.step(parse, "")

    XCTAssertEqual(interpreter.lineNumber, 20)
  }

  func testTwoLineProgramRunsBothLines() throws {
    checkProgramResults("""
25 PRINT 25
40 END
""",
    expecting: "25\n")
  }

  func testRunMultiLineProgramAndFallOffTheEnd() throws {
    checkProgramResults("""
25 GOTO 50
30 PRINT 30
50 PRINT 50
""",
    expecting: "50\n")
  }

  func ifWithFalseResultFallsThrough() throws {
    checkProgramResults("""
25 IF 0 THEN 50
30 PRINT 30
50 PRINT 50
""",
    expecting: "30\n50\n")
  }

  func testIfWithTrueResultDoesGoto() throws {
    checkProgramResults("""
25 IF 1 THEN 50
30 PRINT 30
50 PRINT 50
""",
    expecting: "50\n")
  }

  func testAssignment() throws {
    checkProgramResults("""
10 X = 42
25 PRINT X
""",
    expecting: "42\n")
  }

  func testStringRelationalOperator() {
    checkProgramResults(
      "25 PRINT \"A\"<\"B\"",
      expecting: "1\n")
  }

  func testStringVariableDefaultsToEmptyString() {
    checkProgramResults(
      "25 PRINT A$",
      expecting: "\n")
  }

  func testCallSqr() {
    checkProgramResults(
      "25 PRINT SQR(4)",
      expecting: "2\n")
  }

  func testCallSin() {
    checkProgramResults(
      "25 PRINT SIN(0)",
      expecting: "0\n")
  }

  func testCallLen() {
    checkProgramResults(
      "25 PRINT LEN(\"ABC\")",
      expecting: "3\n")
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

  func testDEFstoresItsFunctionForLater() {
    let parse =
    Parse.line(
      40,
      .def(
        "FNI",
        "X",
        .variable("X", .number),
        .string
      ))

    let interpreter = Interpreter(Program())
    let _ = interpreter.step(parse, "")
    XCTAssertNotNil(interpreter.globals["FNI"])
  }

  func testCallUserDefinedFunction() {
    checkProgramResults("""
10 DEF FNI(X)=X
25 PRINT FNI(3)
""",
    expecting: "3\n")
  }

  func testUsingStaticScope() {
    checkProgramResults("""
10 DEF FNA(Y)= Y + FNB(Y+1)
20 DEF FNB(X)= X+Y
30 Y=1
40 PRINT FNA(3)
""",
    expecting: "8\n")
  }
}

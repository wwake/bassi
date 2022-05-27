//
//  InterpreterTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/9/22.
//

import XCTest
@testable import bassi

class InterpreterTests: XCTestCase {

  func test10REM() throws {
    let program = Program("10 REM Comment")
    let interpreter = Interpreter(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "")
  }

  func test20PRINT() {
    let program = Program("20 PRINT")
    let interpreter = Interpreter(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "\n")
  }

  func test25PRINT42() {
    let program = Program("25 PRINT 42")
    let interpreter = Interpreter(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "42\n")
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
    let program = Program("25 PRINT 2^3^2")
    let interpreter = Interpreter(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "64\n")
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
    let program = Program("""
25 PRINT 25
40 END
""")
    let interpreter = Interpreter(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "25\n")
  }

  func testRunMultiLineProgramAndFallOffTheEnd() throws {
    let program = Program("""
25 GOTO 50
30 PRINT 30
50 PRINT 50
""")
    let interpreter = Interpreter(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "50\n")
  }

  func ifWithFalseResultFallsThrough() throws {
    let program = Program("""
25 IF 0 THEN 50
30 PRINT 30
50 PRINT 50
""")
    let interpreter = Interpreter(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "30\n50\n")
  }

  func testIfWithTrueResultDoesGoto() throws {
    let program = Program("""
25 IF 1 THEN 50
30 PRINT 30
50 PRINT 50
""")
    let interpreter = Interpreter(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "50\n")
  }

  func testAssignment() throws {
    let program = Program("""
10 X = 42
25 PRINT X
""")
    let interpreter = Interpreter(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "42\n")
  }

  func testStringRelationalOperator() {
    let program = Program("25 PRINT \"A\"<\"B\"")
    let interpreter = Interpreter(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "1\n")
  }

  func testStringVariableDefaultsToEmptyString() {
    let program = Program("25 PRINT A$")
    let interpreter = Interpreter(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "\n")
  }

  func testCallSqr() {
    let program = Program("25 PRINT SQR(4)")
    let interpreter = Interpreter(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "2\n")
  }

  func testCallSin() {
    let program = Program("25 PRINT SIN(0)")
    let interpreter = Interpreter(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "0\n")
  }

  func testCallLen() {
    let program = Program("25 PRINT LEN(\"ABC\")")
    let interpreter = Interpreter(program)
    let output = interpreter.run()
    XCTAssertEqual(output, "3\n")
  }

  func testTypeDefaultValueForFunctionIs0() {
    XCTAssertEqual(
      Type.function([.float], .float).defaultValue(),
      Value.string("Undefined function"))
  }
}

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
    do {
      let interpreter = Interpreter(Program(program))
      let output = try interpreter.run()
      XCTAssertEqual(output, expecting)
    } catch {
      XCTFail("\(error)")
    }
  }

  fileprivate func checkExpectedError(_ program: String, expecting: String) {
    do {
      let interpreter = Interpreter(Program(program))
      let _ = try interpreter.run()
      XCTFail("Should have thrown error")
    } catch InterpreterError.error(_, let message){
      XCTAssertEqual(message, expecting)
    } catch {
      XCTFail("Unexpected error \(error)")
    }
  }

  fileprivate func checkPrintWithRelop(_ op: String, _ expected: Int) throws {
    let program = "40 PRINT 10 \(op) 10"
    checkProgramResults(program, expecting: "\(expected)\n")
  }

  fileprivate func checkOppositeRelationalOps(
    _ op1ExpectedTrue: String,
    _ op2ExpectedFalse: String) throws {
      try checkPrintWithRelop(op1ExpectedTrue, 1)
      try checkPrintWithRelop(op2ExpectedFalse, 0)
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

  func testEnd() throws {
    let program = Program("999 END")
    let interpreter = Interpreter(program)
    let _ = try interpreter.run()
    XCTAssertTrue(interpreter.done)
  }

  func testSyntaxErrorStopsInterpreter() throws {
    let program = "10 PRINT {}"
    let interpreter = Interpreter(Program(program))
    let actual = try interpreter.run()
    XCTAssertEqual(
      actual,
      "? error(\"Expected start of expression\")\n")
  }

  func testSkip() throws {
    let parse = Parse(10, Statement.skip)

    let interpreter = Interpreter(Program())

    let output = try interpreter.step(parse, "")
    XCTAssertEqual(output, "")
  }

  func testSimplePrint() throws {
    let parse = Parse(10, Statement.print([]))

    let interpreter = Interpreter(Program())
    let output = try interpreter.step(parse, "")
    XCTAssertEqual(output, "\n")
  }

  func testPrintWithNumericValue() throws {
    let parse =
    Parse(
      35,
      .print([.number(22.0)]))

    let interpreter = Interpreter(Program())
    let output = try interpreter.step(parse, "")
    XCTAssertEqual(output, "22\n")
  }

  func testPrintWithStringValue() throws {
    let parse =
    Parse(
      35,
      .print([.string("hello")]))

    let interpreter = Interpreter(Program())
    let output = try interpreter.step(parse, "")
    XCTAssertEqual(output, "hello\n")
  }

  func testPowers() {
    checkProgramResults(
      "25 PRINT 2^3^2",
      expecting: "64\n")
  }

  func testLogicalOperationsOnIntegersTree() throws {
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
    Parse(
      40,
      .print([expression]))

    let interpreter = Interpreter(Program())
    let output = try interpreter.step(parse, "")
    XCTAssertEqual(output, "7\n")
  }

  func testLogicalOperationsOnIntegers() throws {
    let program = Program("25 PRINT NOT -8 OR 5 AND 4")
    let interpreter = Interpreter(program)
    let output = try interpreter.run()
    XCTAssertEqual(output, "7\n")
  }

  func testVariableDefaultsToZero() throws {
    let program = Program("25 PRINT Y9")
    let interpreter = Interpreter(program)
    let output = try interpreter.run()
    XCTAssertEqual(output, "0\n")
  }

  func testPrintWithUnaryMinus() throws {
    let expr = Expression.op1(
      .minus,
      .number(21.0))
    let interpreter = Interpreter(Program())
    let output = try interpreter.evaluate(expr, [:])
    XCTAssertEqual(output, .number(-21))
  }

  func testPrintWithAddition() throws {
    let parse =
    Parse(
      40,
      .print([
        Expression.make(1, .plus, 2, .plus, 3)
      ])
    )
    
    let interpreter = Interpreter(Program())
    let output = try interpreter.step(parse, "")
    XCTAssertEqual(output, "6\n")
  }

  func testPrintWithSubtraction() throws {
    let parse =
    Parse(
      40,
      .print([
        Expression.make(1, .minus, 2, .minus, 3)
      ]))

    let interpreter = Interpreter(Program())
    let output = try interpreter.step(parse, "")
    XCTAssertEqual(output, "-4\n")
  }

  func testPrintWithMultiplyDivide() throws {
    let parse =
    Parse(
      40,
      .print([
        Expression.make(1, .times, 6, .divide, 3)
      ]))

    let interpreter = Interpreter(Program())
    let output = try interpreter.step(parse, "")
    XCTAssertEqual(output, "2\n")
  }

  func testPrintWithEqualityComparison() throws {
    try checkOppositeRelationalOps("=", "<>")
    try checkOppositeRelationalOps(">=", "<")
    try checkOppositeRelationalOps("<=", ">")
  }

  func test10Goto10() throws {
    let parse =
    Parse(
      10,
      .goto(10))

    let interpreter = Interpreter(Program("10 GOTO 10"))

    XCTAssertEqual(interpreter.nextLineNumber, 10)

    let _ = try interpreter.step(parse, "")

    XCTAssertEqual(interpreter.nextLineNumber, 10)
  }

  func testStepWillTryToGotoMissingLine() throws {
    let parse =
    Parse(
      10,
      .goto(20))

    let interpreter = Interpreter(Program())

    let _ = try interpreter.step(parse, "")

    XCTAssertEqual(interpreter.nextLineNumber, 20)
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

  func testDEFstoresItsFunctionForLater() throws {
    let parse =
    Parse(
      40,
      .def(
        "FNI",
        "X",
        .variable("X", .number),
        .string
      ))

    let interpreter = Interpreter(Program())
    let _ = try interpreter.step(parse, "")
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

  func testCallOnUndefinedFunctionFails() {
    checkExpectedError(
      "10 PRINT FNX(0)",
      expecting: "Attempted call on undefined function FNX")
  }
  
  func testPrintIntegerUsesNoDecimals() {
    checkProgramResults(
      "1 PRINT 42",
      expecting: "42\n")
  }

  func testPrintFloatDoesUseDecimals() {
    checkProgramResults(
      "1 PRINT 0.875000",
      expecting: "0.875000\n")
  }

  func testNumericSystemFunctions() {
    checkProgramResults(
      "1 PRINT ABS(-1)",
      expecting: "1\n")

    checkProgramResults(
      "1 PRINT ATN(1)",
      expecting: "0.785398\n")

    checkProgramResults(
      "1 PRINT COS(1)",
      expecting: "0.540302\n")

    checkProgramResults(
      "1 PRINT EXP(1)",
      expecting: "2.718282\n")

    checkProgramResults(
      "1 PRINT FRE(1)",
      expecting: "100000\n")

    checkProgramResults(
      "1 PRINT INT(41.99)",
      expecting: "41\n")

    checkProgramResults(
      "1 PRINT LOG(2.71)",
      expecting: "0.996949\n")

    checkProgramResults(
      "1 PRINT SGN(-41.99)",
      expecting: "-1\n")

    checkProgramResults(
      "1 PRINT SIN(1.56)",
      expecting: "0.999942\n")

    checkProgramResults(
      "1 PRINT SQR(64)",
      expecting: "8\n")

    checkProgramResults(
      "1 PRINT TAN(3.14)",
      expecting: "-0.001593\n")
  }

  func testRandomNumbers() throws {
    try (1...1000).forEach { _ in
      let interpreter = Interpreter(Program("1 PRINT RND(0)"))
      let output = try interpreter.run()
      let value = Float(output.dropLast())!
      XCTAssertTrue(value >= 0 && value < 1)
    }
  }

  func testStringSystemFunctions() {
    checkProgramResults(
      "1 PRINT LEN(\"ABCDE\")",
      expecting: "5\n")

    checkProgramResults(
      "1 PRINT CHR$(42)",
      expecting: "*\n")

    checkProgramResults(
      "1 PRINT STR$(-21)",
      expecting: "-21\n")
  }

  func testASCfunction() {
    checkProgramResults(
      "1 PRINT ASC(\"DAD\")",
      expecting: "68\n")

    checkProgramResults(
      "1 PRINT ASC(\"\")",
      expecting: "0\n")
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
      expecting: "21.250000\n")

    checkProgramResults(
      "1 PRINT VAL(\"junk\")",
      expecting: "0\n")
  }

  func testArrayValuesEqualIfDimensionsAndContentsAreEqual() {
    XCTAssertEqual(
      Value.array([3], [.number(0), .number(0), .number(0)]),
      Value.array([3], [.number(0), .number(0), .number(0)]))
  }

  func testDIMknowsTypeAndSize() throws {
    let program = Program("10 DIM A(2)")
    let interpreter = Interpreter(program)
    let _ = try interpreter.run()
    XCTAssertEqual(
      interpreter.globals["A"]!,
      .array(
        [3],
        [.number(0), .number(0), .number(0)]))
  }

  func testDIMknowsTypeAndSizeForMultiDArray() throws {
    let program = Program("10 DIM A(2,1,2)")

    let interpreter = Interpreter(program)
    let _ = try interpreter.run()

    XCTAssertEqual(
      interpreter.globals["A"]!,
      .array(
        [3,2,3],
        Array<Value>(
          repeating: .number(0.0),
          count: 3*2*3)))
  }

  func testDIMmayNotRedeclareVariables() throws {
    do {
      let program = Program("10 DIM A(2)")
      let interpreter = Interpreter(program)
      interpreter.globals["A"] = .number(27)
      let _ = try interpreter.run()
    } catch InterpreterError.error(_, let message) {
      XCTAssertEqual(message, "Can't redeclare array A")
    }
  }

  func testArrayAccess() {
    checkProgramResults(
      "10 DIM A(3)\n20 PRINT A(0)",
      expecting: "0\n")
  }

  func testCantAccessNonArrayWithSubscript() {
    checkExpectedError(
      "10 A = 7\n20 PRINT A(0)",
      expecting: "Tried to subscript non-array A")
  }

  func testAssignmentToArray() {
    checkProgramResults("""
10 DIM A(3)
20 A(1)=17
25 A(2)=42
30 PRINT A(1)
40 PRINT A(2)
""",
      expecting: "17\n42\n")
  }

  func testArrayAssignmentToAlreadyNonArrayVariableFails() {
    checkExpectedError("""
10 A=3
20 A(1)=17
""",
      expecting: "Tried to subscript non-array A")
  }

  func testArrayAssignmentWithoutDIMdefaultsToSize10() throws {
    let program = Program("10 A(2) = 3")
    let interpreter = Interpreter(program)
    let _ = try interpreter.run()

    var expected = Array<Value>(
      repeating: .number(0),
      count: 11)
    expected[2] = .number(3)

    XCTAssertEqual(
      interpreter.globals["A"]!,
      .array([11], expected)
    )
  }

  func testArrayAccessWithoutDIMdefaultsToSize10() throws {
    let program = Program("10 PRINT A(2)")
    let interpreter = Interpreter(program)
    let _ = try interpreter.run()

    XCTAssertEqual(
      interpreter.globals["A"]!,
      .array([11], Array<Value>(repeating: .number(0), count: 11))
    )
  }

  func testErrorMessageIncludesLineNumber() throws {
    do {
      let program = "20 PRINT A(-2)"
      let interpreter = Interpreter(Program(program))
      let _ = try interpreter.run()
      XCTFail("Should have thrown error")
    } catch InterpreterError.error(let lineNumber, _) {
      XCTAssertEqual(lineNumber, 20)
    }
  }
  
  func testBoundsCheckArrayAccess() {
    checkExpectedError(
      "20 PRINT A(11)",
      expecting: "array access out of bounds"
    )

    checkExpectedError(
      "25 PRINT A(-1)",
      expecting: "array access out of bounds"
    )
  }

  func testBoundsCheckArrayWrite() {
    checkExpectedError(
      "20 A(11)=5",
      expecting: "array access out of bounds")

    checkExpectedError(
      "25 A(-1)=27",
      expecting: "array access out of bounds")
  }

  func testMultiDArrayReadAndWrite() {
    checkProgramResults("""
20 A(1,2)=12
25 A(1,1)=11
30 PRINT A(1,2)
35 PRINT A(1,1)
""",
    expecting: "12\n11\n"
    )
  }

  func testMultiDArrayFullReadAndWrite() {
    checkProgramResults(
"""
10 X=1
20 FOR I=0 TO 2
30 FOR J=0 TO 4
40 B(I,J) = X
50 X = X+1
60 NEXT J
70 NEXT I
80 REM
220 FOR I=0 TO 2
230 FOR J=0 TO 4
240 PRINT B(I,J)
250 NEXT J
260 NEXT I
400 END
""",
    expecting: """
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15

""")
  }

  func testStringArrayElementsStartEmpty() {
    checkProgramResults(
      "10 PRINT A$(2)",
      expecting: "\n")
  }

  func testStringArray() {
    checkProgramResults(
"""
10 DIM A$(3)
20 A$(3)="hello"
30 PRINT A$(3)
""",
      expecting: "hello\n")
  }

  func testFORwithPositiveStep() {
    checkProgramResults(
"""
10 FOR X=1 TO 3
20 PRINT X
35 NEXT X
40 PRINT X
""",
    expecting: "1\n2\n3\n3\n")
  }

  func testFORwithNegativeStep() {
    checkProgramResults(
"""
10 FOR X=3 TO 1 STEP -1
20 PRINT X
35 NEXT X
40 PRINT X
""",
expecting: "3\n2\n1\n1\n")
  }

  func testFORstartingOutOfRange_DoesntExecute_but_DoesAdjustVariable()
  {
    checkProgramResults(
"""
10 FOR X=4 TO 2
20 PRINT 999
35 NEXT X
40 PRINT X
""",
      expecting: "3\n"
    )
  }

  func testFORtestsVarPlusStep()
  {
    checkProgramResults(
"""
10 FOR X=2 TO 2
20 PRINT 999
35 NEXT X
40 PRINT X
""",
expecting: "999\n2\n"
    )
  }

  func testFORwithoutNEXTreportsError() {
    checkExpectedError(
      "10 FOR A0=1 TO 3",
      expecting: "Found FOR without NEXT: A0")
  }

  func testNEXTwithoutFORreportsError() {
    checkExpectedError(
      "30 NEXT X",
      expecting: "Found NEXT without preceding FOR")
  }

  func testNEXTvariableMustMatchFORvariable() {
    checkExpectedError(
"""
10 FOR A=1 TO 2
30 NEXT Z
40 NEXT A
""",
      expecting: "NEXT variable must match corresponding FOR")
  }

  func testGOSUB() {
    checkProgramResults(
"""
10 GOSUB 100
15 PRINT 52
20 END
100 PRINT 42
110 RETURN
""",
      expecting: "42\n52\n")
  }

  func testGOSUBinSubroutine() {
    checkProgramResults(
"""
10 GOSUB 100
20 PRINT 20
30 END
50 PRINT 50
60 RETURN
100 PRINT 100
110 GOSUB 50
120 RETURN
""",
  expecting: "100\n50\n20\n")
  }

  func testRETURNwithoutGOSUB() {
    checkExpectedError("10 RETURN", expecting: "RETURN called before GOSUB")
  }

  func testON_GOTO() {
    checkProgramResults(
"""
10 ON 2 GOTO 20, 30, 20
15 PRINT 15
20 PRINT 20
30 PRINT 30
""",
      expecting: "30\n")
  }

  func testON_GOTOwithNegativeValueThrowsError() {
    checkExpectedError(
"""
10 ON -1 GOTO 20, 20
15 PRINT 15
16 END
20 PRINT 20
""",
expecting: "?ILLEGAL QUANTITY")
  }

  func testON_GOTOwith0GoesToNextLine() {
    checkProgramResults(
"""
10 ON 0 GOTO 20, 20
15 PRINT 15
16 END
20 PRINT 20
""",
expecting: "15\n")
  }

  func testON_GOTOwithTooLargeValueGoesToNextLine() {
    checkProgramResults(
"""
10 ON 3 GOTO 20, 20
15 PRINT 15
16 END
20 PRINT 20
""",
expecting: "15\n")
  }
}

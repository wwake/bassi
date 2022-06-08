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

  fileprivate func checkPrintWithRelop(_ op: Token, _ expected: Int) throws {
    let parse =
    Parse.line(
      40,
      .print([
        Expression.make(10, op, 10)
      ]))

    let interpreter = Interpreter(Program())
    let output = try interpreter.step(parse, "")
    XCTAssertEqual(output, "\(expected)\n")
  }

  fileprivate func checkRelop(
    _ op1ExpectedTrue: Token,
    _ op2ExpectedFalse: Token) throws {
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

  func testEnd() {
    let program = Program("999 END")
    let interpreter = Interpreter(program)
    let _ = interpreter.run()
    XCTAssertTrue(interpreter.done)
  }

  func testSyntaxErrorStopsInterpreter() throws {
    let program = "10 PRINT {}"
    let interpreter = Interpreter(Program(program))
    let actual = interpreter.run()
    XCTAssertEqual(
      actual,
      "? expectedStartOfExpression\n")
  }

  func testSkip() throws {
    let parse = Parse.line(10, Parse.skip)

    let interpreter = Interpreter(Program())

    let output = try interpreter.step(parse, "")
    XCTAssertEqual(output, "")
  }

  func testSimplePrint() throws {
    let parse =
    Parse.line(10, Parse.print([]))

    let interpreter = Interpreter(Program())
    let output = try interpreter.step(parse, "")
    XCTAssertEqual(output, "\n")
  }

  func testPrintWithNumericValue() throws {
    let parse =
    Parse.line(
      35,
      .print([.number(22.0)]))

    let interpreter = Interpreter(Program())
    let output = try interpreter.step(parse, "")
    XCTAssertEqual(output, "22\n")
  }

  func testPrintWithStringValue() throws {
    let parse =
    Parse.line(
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
    Parse.line(
      40,
      .print([expression]))

    let interpreter = Interpreter(Program())
    let output = try interpreter.step(parse, "")
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

  func testPrintWithAddition() throws {
    let parse =
    Parse.line(
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
    Parse.line(
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
    Parse.line(
      40,
      .print([
        Expression.make(1, .times, 6, .divide, 3)
      ]))

    let interpreter = Interpreter(Program())
    let output = try interpreter.step(parse, "")
    XCTAssertEqual(output, "2\n")
  }

  func testPrintWithEqualityComparison() throws {
    try checkRelop(.equals, .notEqual)
    try checkRelop(.greaterThanOrEqualTo, .lessThan)
    try checkRelop(.lessThanOrEqualTo, .greaterThan)
  }

  func test10Goto10() throws {
    let parse =
    Parse.line(
      10,
      .goto(10))

    let interpreter = Interpreter(Program("10 GOTO 10"))

    XCTAssertEqual(interpreter.nextLineNumber, 10)

    let _ = try interpreter.step(parse, "")

    XCTAssertEqual(interpreter.nextLineNumber, 10)
  }

  func testStepWillEvenGotoMissingLine() throws {
    let parse =
    Parse.line(
      10,
      .goto(20))

    let interpreter = Interpreter(Program())

    let _ = try interpreter.step(parse, "")

    XCTAssertEqual(interpreter.nextLineNumber, 20)
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
    Parse.line(
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
    checkProgramResults(
      "10 PRINT FNX(0)",
      expecting: "error(10, \"Attempted call on undefined function FNX\")\n")
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

  func testRandomNumbers() {
    (1...1000).forEach { _ in
      let interpreter = Interpreter(Program("1 PRINT RND(0)"))
      let output = interpreter.run()
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

  func testDIMknowsTypeAndSize() {
    let program = Program("10 DIM A(2)")
    let interpreter = Interpreter(program)
    let _ = interpreter.run()
    XCTAssertEqual(
      interpreter.globals["A"]!,
      .array(
        [3],
        [.number(0), .number(0), .number(0)]))
  }

  func testDIMknowsTypeAndSizeForMultiDArray() {
    let program = Program("10 DIM A(2,1,2)")

    let interpreter = Interpreter(program)
    let _ = interpreter.run()

    XCTAssertEqual(
      interpreter.globals["A"]!,
      .array(
        [3,2,3],
        Array<Value>(
          repeating: .number(0.0),
          count: 3*2*3)))
  }

  func testDIMmayNotRedeclareVariables() {
    let program = Program("10 DIM A(2)")
    let interpreter = Interpreter(program)
    interpreter.globals["A"] = .number(27)
    let output = interpreter.run()
    XCTAssertEqual(
      output,
      "error(10, \"Can\\'t redeclare array A\")")
  }

  func testArrayAccess() {
    checkProgramResults(
      "10 DIM A(3)\n20 PRINT A(0)",
      expecting: "0\n")
  }

  func testCantAccessNonArrayWithSubscript() {
    checkProgramResults(
      "10 A = 7\n20 PRINT A(0)",
      expecting: "error(20, \"Tried to subscript non-array A\")\n")
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
    checkProgramResults("""
10 A=3
20 A(1)=17
""",
                        expecting: "?? attempted to use non-array as an array\n")
  }

  func testArrayAssignmentWithoutDIMdefaultsToSize10() {
    let program = Program("10 A(2) = 3")
    let interpreter = Interpreter(program)
    let _ = interpreter.run()

    var expected = Array<Value>(
      repeating: .number(0),
      count: 11)
    expected[2] = .number(3)

    XCTAssertEqual(
      interpreter.globals["A"]!,
      .array([11], expected)
    )
  }

  func testArrayAccessWithoutDIMdefaultsToSize10() {
    let program = Program("10 PRINT A(2)")
    let interpreter = Interpreter(program)
    let _ = interpreter.run()

    XCTAssertEqual(
      interpreter.globals["A"]!,
      .array([11], Array<Value>(repeating: .number(0), count: 11))
    )
  }

  func testBoundsCheckArrayAccess() {
    checkProgramResults("""
20 PRINT A(11)
25 PRINT A(-1)
""",
      expecting:
"""
error(20, "array access out of bounds")
error(25, "array access out of bounds")

""")
  }

  func testBoundsCheckArrayWrite() {
    checkProgramResults("""
20 A(11)=5
""",
      expecting: "error(20, \"array access out of bounds\")")

    checkProgramResults("""
25 A(-1)=27
""",
      expecting: "error(25, \"array access out of bounds\")")
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
20 I = 0
25 IF I > 2 THEN 220
30 J = 0
40 IF J > 4 THEN 100
45 B(I,J) = X
50 X = X+1
55 J = J+1
60 GOTO 40
100 I=I+1
110 GOTO 25
220 I = 0
225 IF I > 2 THEN 400
230 J = 0
240 IF J > 4 THEN 300
245 PRINT B(I,J)
255 J = J+1
260 GOTO 240
300 I=I+1
310 GOTO 225
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

}

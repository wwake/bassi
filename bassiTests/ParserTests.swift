//
//  ParserTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/10/22.
//

import XCTest
@testable import bassi

class ParserTests: XCTestCase {
  func checkOneStatement(
    _ program: String,
    _ expected: Statement)
  {
    let parser = Parser()
    let result = parser.parse(program)
    XCTAssertEqual(
      result.statements,
      [expected]
    )
  }

  func checkStatements(
    _ program: String,
    _ expected: [Statement])
  {
    let parser = Parser()
    let result = parser.parse(program)
    XCTAssertEqual(
      result.statements,
      expected
    )
  }

  func checkExpression(
    _ expression: String,
    _ expected: Expression) {

      let input = "10 PRINT \(expression)"
      let parser = Parser()
      let result = parser.parse(input)
      XCTAssertEqual(
        result,
        Parse(
          10,
          [.print([.expr(expected)], true)])
      )
    }

  func checkError(
    _ program: String,
    _ expected: String)
  {
    let line = program
    let parser = Parser()
    let output = parser.parse(line)

    if case .error(_, _, let actualMessage) = output.statements[0] {
      XCTAssertEqual(
        actualMessage,
        expected)
      return
    }

    XCTFail("no error found")
  }

  func number(_ number: Float) -> Printable {
    .expr(.number(number))
  }

  func test10END() throws {
    let parser = Parser()

    XCTAssertEqual(
      parser.parse("1 END"),
      Parse(1, [.end]))

    XCTAssertEqual(
      parser.parse("99999 END"),
      Parse(99999, [.end]))
  }

  func testLineNumberIsInRange0to99999() {
    checkError(
      "0 END", "Line number must be between 1 and 99999")

    checkError(
      "100000 END", "Line number must be between 1 and 99999")
  }

  func test10REM() throws {
    checkOneStatement(
      "10 REM whatever",
      .skip
    )
  }

  func testNoLineNumber() {
    checkError(
      "REM remark",
      "Line number is required; found remark")
  }

  func testPrintStatement() {
    checkOneStatement(
      "25 PRINT",
      .print([], true)
    )
  }

  func testPrintStatementWithNumber() {
    checkOneStatement(
      "25 PRINT 42",
      .print([.expr(.number(42.0))], true)
    )
  }

  func testPrintPrintIsError() {
    checkError(
      "25 PRINT PRINT",
      "Expected start of expression"
    )
  }

  func testMultipleStatementsOnOneLine() {
    checkStatements(
      "10 PRINT 10: PRINT 20",
      [.print([number(10)], true), .print([number(20)], true)]
    )
  }

  func testMultipleEmptyPrintStatementsOnOneLine() {
    checkStatements(
      "10 PRINT: PRINT",
      [.print([], true), .print([], true)]
    )
  }

  func testSemicolonAtEndOfPrintSuppressesNewline() {
    checkStatements("10 PRINT;", [.print([.thinSpace], false)])
  }

  func testCommaAtEndOfPRINTsuppressesNewline() {
    checkStatements("10 PRINT,", [.print([.tab], false)])
  }

  func testCommaInPRINTyieldsTab() {
    checkStatements(
      "10 PRINT 1,2",
      [.print([.expr(.number(1)), .tab, .expr(.number(2))], true)])
  }

  func testGoto() throws {
    checkOneStatement(
      "10 GOTO 10",
      .goto(10)
    )
  }

  func testGotoWithMissingTarget() throws {
    checkError(
      "10 GOTO",
      "Missing target of GOTO"
    )
  }

  func testIfThenLineNumber() throws {
    checkOneStatement(
      "42 IF 0 THEN 43",
      .ifGoto(.number(0), 43)
    )
  }

  func testIfMustCheckNumericType() throws {
    checkError(
      "42 IF A$ THEN 43",
      "Numeric type is required")
  }

  func testIfMissingThenGetsError() throws {
    checkError(
      "42 IF 0 PRINT",
      "Missing 'THEN'"
    )
  }

  func testIfThenMissingTargetGetsError() throws {
    checkError(
      "42 IF 0 THEN",
      "Unknown statement"
    )
  }

  func testIfWithStatement() {
    checkOneStatement(
      "42 IF 1 THEN PRINT 42",
      .`if`(.number(1), [.print([number(42)], true)])
    )
  }
  
  func testIfWithMultipleStatements() {
    checkOneStatement(
      "42 IF 1 THEN PRINT 42: PRINT 43",
      .`if`(
        .number(1),
        [
          .print([number(42)], true),
          .print([number(43)], true)
        ])
    )
  }

  func testNestedIFsWithMultipleStatements() {
    checkOneStatement(
      "42 IF 1 THEN PRINT 42: IF 0 THEN PRINT 43: PRINT 44",
      .`if`(
        .number(1),
        [
          .print([number(42)], true),
          .`if`(
            .number(0),
            [
              .print([number(43)], true),
              .print([number(44)], true)])])
    )
  }

  func testAssignmentStatementWithNumber() {
    checkOneStatement(
      "25 X = 42",
      .assign(
        .variable("X", .number),
        .number(42.0))
    )
  }

  func testAssignmentStatementWithLET() {
    checkOneStatement(
      "25 LET A = 2",
      .assign(
        .variable("A", .number),
        .number(2.0))
    )
  }

  func testAssignMissingEqualSign() {
    checkError(
      "42 HUH REMARK",
      "Assignment is missing '='"
    )
  }

  func testLETMissingAssignment() {
    checkError(
      "42 LET",
      "LET is missing variable to assign to"
    )
  }

  func testAssignStringToNumberFails() {
    checkError(
      "17 A=B$",
      "Type mismatch"
    )
  }

  func testStandaloneStringInExpression() {
    checkOneStatement(
      "25 A$ = \"body\"",
      .assign(
        .variable("A$", .string),
        .string("body"))
    )
  }

  func testPrintString() {
    checkOneStatement(
      "25 PRINT \"body\"",
      .print(
        [.expr(.string("body"))], true)
    )
  }

  func testStringCantDoArithmetic() {
    checkError("17 A=-B$", "Numeric type is required")

    checkError("17 A=B$^3", "Type mismatch")
    checkError("17 A=3^B$", "Type mismatch")

    checkError("17 A=B$*C$", "Type mismatch")
    checkError("17 A=3/B$", "Type mismatch")

    checkError("17 A=B$+C$", "Type mismatch")
    checkError("17 A=3-B$", "Type mismatch")

    checkError("17 A=NOT B$", "Numeric type is required")
    checkError("17 A=B$ AND 3", "Type mismatch")
    checkError("17 A=42 OR B$", "Type mismatch")
  }

  func testDefDefinesHelperFunctions() {
    checkOneStatement(
      "25 DEF FNI(x)=x",
      .def(
        "FNI",
        "X",
        .variable("X", .number),
        .function([.number], .number)
      )
    )
  }

  func testDefErrorMessages() {
    checkError("17 DEF F(X)=X", "DEF requires a name of the form FNx")
    checkError("17 DEF FN(x)=X", "DEF requires a name of the form FNx")
    checkError("17 DEF FNX9(x)=X", "DEF function name cannot be followed by extra letters")
    checkError("17 DEF FNI x)=X", "Missing '('")
    checkError("17 DEF FNZ()=X", "Variable is required")
    checkError("17 DEF FNA(x=X", "DEF requires ')' after parameter")
    checkError("17 DEF FNP(x) -> X", "DEF requires '=' after parameter definition")
  }

  func testPredefinedFunction() {
    checkOneStatement(
      "25 PRINT SQR(4)",
      .print(
        [.expr(.predefined("SQR", [.number(4)], .number))],
        true
      )
    )
  }

  func testPredefinedStringFunctionReturnType() {
    checkOneStatement(
      "25 PRINT CHR$(4)",
      .print(
        [.expr(.predefined("CHR$", [.number(4)], .string))],
        true
      )
    )
  }

  func testChrParsesString() {
    checkExpression(
      "ASC(\"\")",
      .predefined(
        "ASC",
        [.string("")],
        .number)
    )
  }
  
  func testPredefinedFunctionEnforcesTypes() {
    checkError(
      "25 PRINT SQR(\"X\")",
      "Type mismatch"
    )
  }

  func testCantAssignPredefinedStringFunctionCallToNumericVariable() {
    checkError(
      "25 A=CHR$(17)",
      "Type mismatch"
    )
  }

  func testPredefinedFunctionEnforcesNumberOfArguments() {
    checkError(
      "25 PRINT LEFT$(\"X\")",
      "Type mismatch"
    )
  }

  func testPredefinedFunctionCallSupportsMultipleArguments() {
    checkExpression(
      "LEFT$(\"S\", 1)",
      .predefined(
        "LEFT$",
        [.string("S"), .number(1)],
        .string)
    )
  }

  func testPredefinedFunctionDetectsTypeMismatchForMultipleArguments() {
    checkError(
      "10 PRINT LEFT$(\"S\", \"T\")",
      "Type mismatch"
    )
  }

  func testMIDworksWithThreeArguments() {
    checkExpression(
      "MID$(\"STR\", 1, 2)",
      .predefined(
        "MID$",
        [.string("STR"), .number(1), .number(2)],
        .string)
    )
  }

  func testMIDworksWithTwoArguments() {
    checkExpression(
      "MID$(\"STR\", 1)",
      .predefined(
        "MID$",
        [.string("STR"), .number(1), .missing],
        .string)
    )
  }

  func testDefCall() {
    checkOneStatement(
      "10 PRINT FNI(3)",
      .print([
        .expr(.userdefined(
          "FNI",
          .number(3) ))
      ], true))
  }

  func testDefCallMustTakeNumericArgument() {
    checkError(
      "10 PRINT FNI(\"str\")",
      "Type mismatch")
  }

  func testUserDefinedFunctionsMustHaveNumericResult() {
    checkError("""
10 DEF FNA(Y)="string"
""",
      "Numeric type is required")
  }

  func testDIMNumber() {
    checkOneStatement(
      "10 DIM A(5)",
      .dim([DimInfo("A", [.number(5)], .number)])
    )
  }

  func testDIMString() {
    checkOneStatement(
      "10 DIM Z9$(5)",
      .dim([DimInfo("Z9$", [.number(5)], .string)])
    )
  }

  func testMultiDimensionalDIM() {
    checkOneStatement(
      "10 DIM Z(3,4,5)",
      .dim([DimInfo("Z", [.number(3),.number(4),.number(5)], .number)])
    )
  }

  func testDimWithMultipleArrays() {
    checkOneStatement(
      "10 DIM Z(1,2), W$(3,4)",
      .dim([DimInfo("Z", [.number(1),.number(2)], .number),
            DimInfo("W$", [.number(3),.number(4)], .string)])
    )
  }

  func testDimWithExpressions() {
    checkOneStatement(
      "10 DIM Z(2*3)",
      .dim([DimInfo("Z", [.op2(.times, .number(2), .number(3))], .number)]))
  }

  func testRightParendErrorInDim() {
    checkError(
      "10 DIM Z(3",
      "Missing ')'")
  }
  
  func testFetchFromArray() {
    checkOneStatement(
      "10 PRINT A(0)",
      .print([
        .expr(.arrayAccess("A", .number, [.number(0)]))
      ], true)
    )
  }

  func testFetchFromMultiDArray() {
    checkOneStatement(
      "10 PRINT A(1,2)",
      .print([
        .expr(.arrayAccess("A", .number, [.number(1),
                                    .number(2)]))
      ], true)
    )
  }

  func testFORwithoutSTEP() {
    checkOneStatement(
      "10 FOR X=1 TO 10",
      .`for`("X", .number(1), .number(10), .number(1))
    )
  }

  func testFORwithSTEP() {
    checkOneStatement(
      "10 FOR X=1 TO 10 STEP 5",
      .`for`("X", .number(1), .number(10), .number(5))
    )
  }

  func testFORrequiresVariableEqualsAndTO() {
    checkError(
      "10 FOR 1 TO 10",
      "Variable is required"
    )
    checkError(
      "10 FOR X (1) TO 10",
      "'=' is required"
    )
    checkError(
      "10 FOR X = 1, 10",
      "'TO' is required"
    )
  }

  func testFORrequiresNumericExpressions() {
    checkError(
      "10 FOR X=\"string\" TO 10",
      "Numeric type is required"
    )
    checkError(
      "10 FOR X=1 TO \"10\"",
      "Numeric type is required"
    )
    checkError(
      "10 FOR X = 1 TO 10 STEP \"X\"",
      "Numeric type is required"
    )
  }

  func testNEXTwithVariable() {
    checkOneStatement(
      "10 NEXT Z9",
      .next("Z9")
    )
  }

  func testNEXTrequiresVariable() {
    checkError(
      "10 NEXT",
      "Variable is required"
    )
  }

  func testGOSUB() {
    checkOneStatement(
      "10 GOSUB 20",
      .gosub(20))
  }

  func testGOSUBrequiresLineNumber() {
    checkError(
      "10 GOSUB",
      "Missing target of GOSUB")

    checkError(
      "10 GOSUB X",
      "Missing target of GOSUB")
  }

  func testRETURN() {
    checkOneStatement(
      "10 RETURN",
      .`return`)
  }

  func testRETURNstandsAlone() {
    checkError(
      "10 RETURN X",
      "Extra characters at end of line")
  }

  func testON_GOTO() {
    checkOneStatement(
      "10 ON 2 GOTO 10,20,30",
      .onGoto(
        .number(2),
        [10, 20, 30]))
  }

  func testONmissingGOTOisError() {
    checkError(
      "10 ON 2 THEN 10,20,30",
      "GOTO is missing")
  }

  func testONmissingLineNumbersIsError() {
    checkError(
      "10 ON 2 GOTO X",
      "ON..GOTO requires at least one line number after GOTO")
  }

  func testONmissingLineNumberAfterCommaIsError() {
    checkError(
      "10 ON 2 GOTO 10,",
      "ON..GOTO requires line number after comma")
  }

  func testSimpleStatementsJustCount() {
    XCTAssertEqual(
      Statement.count([.gosub(1), .gosub(2), .goto(3)]),
      3)
  }

  func testIfStatementAddsCountOfChildren() {
    XCTAssertEqual(
      Statement.count(
      [
        .goto(1),
        .if(.number(1),
            [.goto(2), .gosub(3)])
      ]),
      4
      )
  }

  func testIfStatementAddsCountOfChildrenRecursively() {
    XCTAssertEqual(
      Statement.count(
        [
          .goto(1),
          .if(.number(1),
              [.goto(2),
               .if(.number(3),
                   [.gosub(3),
                    .gosub(4),
                    .gosub(5)])])
        ]),
      7
    )
  }

  func testLocationNumbering() {
    // gosub : gosub : if c then gosub: if c2 then gosub: gosub
    let innerIf : Statement = .`if`(.number(0), [.gosub(5), .gosub(6)])
    let outerIf : Statement = .`if`(.number(0), [.gosub(3), innerIf])

    let list : [Statement] = [
      .gosub(0),
      .gosub(1),
      outerIf
    ]

    XCTAssertEqual(Statement.at(list, 0), .gosub(0))
    XCTAssertEqual(Statement.at(list, 1), .gosub(1))
    XCTAssertEqual(Statement.at(list, 2), outerIf)
    XCTAssertEqual(Statement.at(list, 3), .gosub(3))
    XCTAssertEqual(Statement.at(list, 4), innerIf)
    XCTAssertEqual(Statement.at(list, 5), .gosub(5))
    XCTAssertEqual(Statement.at(list, 6), .gosub(6))
  }

  func testStop() throws {
    checkOneStatement(
      "10 stop",
      .stop
    )
  }
}

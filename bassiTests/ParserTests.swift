//
//  ParserTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/10/22.
//

import XCTest
@testable import bassi

class ParserTests: XCTestCase {
  func checkError(
    _ program: String,
    _ expected: ParseError)
  {
    let line = program
    let parser = Parser()
    let output = parser.parse(line)
    XCTAssertEqual(
      output,
      Parse(output.lineNumber, .error(expected)))
  }

  func checkStatement(
    _ program: String,
    _ expected: Statement)
  {
    let parser = Parser()
    let result = parser.parse(program)
    XCTAssertEqual(
      result.statement,
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
          .print([expected]))
      )
    }

  func checkRelational(_ relation: String, _ token: TokenType) throws {
    checkExpression(
      "1" + relation + "2",
      Expression.make(1, token, 2)
    )
  }

  func test10END() throws {
    let parser = Parser()

    XCTAssertEqual(
      parser.parse("1 END"),
      Parse(1, .end))

    XCTAssertEqual(
      parser.parse("99999 END"),
      Parse(99999, .end))
  }

  func testLineNumberIsInRange0to99999() {
    checkError(
      "0 END", ParseError.error("Line number must be between 1 and 99999"))

    checkError(
      "100000 END", ParseError.error("Line number must be between 1 and 99999"))
  }

  func test10REM() throws {
    checkStatement(
      "10 REM whatever",
      .skip
    )
  }

  func testNoLineNumber() {
    checkError(
      "REM remark",
      .error("Line number is required; found remark"))
  }

  func testPrintStatement() {
    checkStatement(
      "25 PRINT",
      .print([])
    )
  }

  func testPrintStatementWithNumber() {
    checkStatement(
      "25 PRINT 42",
      .print([.number(42.0)])
    )
  }

  func testPrintPrintIsError() {
    checkError(
      "25 PRINT PRINT",
      .error("Expected start of expression")
    )
  }

  func testGoto() throws {
    checkStatement(
      "10 GOTO 10",
      .goto(10)
    )
  }

  func testGotoWithMissingTarget() throws {
    checkError(
      "10 GOTO",
      .error("Missing target of GOTO")
    )
  }

  func testOrExpr() throws {
    checkExpression(
      "2 OR 4 AND 5",
      .op2(
        .or,
        .number(2),
        .op2(
          .and,
          .number(4),
          .number(5)))
    )
  }

  func testAndExpr() throws {
    checkExpression(
      "2 < 3 AND 4",
      Expression.make(2, .lessThan, 3, .and, 4)
    )
  }
  
  func testRelationalHasPrecedenceOverNegation() throws {
    checkExpression(
      "NOT 2 < 3",
      Expression.make(.not, 2, .lessThan, 3)
    )
  }

  func testRelationalComparison() throws {
    try checkRelational("=", .equals)
    try checkRelational("<", .lessThan)
    try checkRelational("<=", .lessThanOrEqualTo)
    try checkRelational("<>", .notEqual)
    try checkRelational(">", .greaterThan)
    try checkRelational(">=", .greaterThanOrEqualTo)
  }

  func testSimpleAddition() throws {
    checkExpression(
      "1+2",
      Expression.make(1, .plus, 2)
    )
  }

  func testAdditionIsLeftAssociative() throws {
    checkExpression(
      "1+2+3",
      Expression.make(1, .plus, 2, .plus, 3))
  }

  func testSubtraction() throws {
    checkExpression(
      "1-2-3",
      Expression.make(1, .minus, 2, .minus, 3)
    )
  }

  func testMultiplyDivide() throws {
    checkExpression(
      "1*6/3",
      Expression.make(1, .times, 6, .divide, 3)
    )
  }

  func testPowerIsLeftAssociative() throws {
    checkExpression(
      "2^3^4",
      Expression.make(2, .exponent, 3, .exponent, 4)
    )
  }

  func testUnaryMinusHasPrecedenceOverPower() throws {
    checkExpression(
      "-2^3",
      Expression.make(.minus, 2, .exponent, 3)
    )
  }

  func testParenthesizedExpression() throws {
    checkExpression(
      "((21))",
      .number(21.0)
    )
  }

  func testMissingRightParentheses() {
    let expression = "(((21)"
    checkError(
      "10 PRINT \(expression)",
      .error("Missing ')'")
    )
  }

  func testPrintImproperExpression() {
    checkError(
      "10 PRINT +",
      .error("Expected start of expression")
    )
  }
  func testErrorWhenFactorIsNotValid() {
    let expression = "(((*"
    checkError(
      "10 PRINT \(expression)",
      .error("Expected start of expression")
    )
  }

  func testUnaryMinus() throws {
    checkExpression (
      "---21",
      .op1(.minus,
           .op1(.minus,
                .op1(.minus,
                     .number(21.0))))
    )
  }

  func testVariable() throws {
    checkExpression(
      "X",
      .variable("X", .number))
  }

  func testIfThenLineNumber() throws {
    checkStatement(
      "42 IF 0 THEN 43",
      .`if`(.number(0), 43)
    )
  }

  func testIfMustCheckNumericType() throws {
    checkError(
      "42 IF A$ THEN 43",
      .error("Numeric type is required"))
  }

  func testIfMissingThenGetsError() throws {
    checkError(
      "42 IF 0 PRINT",
      .error("Missing 'THEN'")
    )
  }

  func testIfThenMissingTargetGetsError() throws {
    checkError(
      "42 IF 0 THEN",
      .error("Missing target of THEN")
    )
  }

  func testAssignmentStatementWithNumber() {
    checkStatement(
      "25 X = 42",
      .assign(
          .variable("X", .number),
          .number(42.0))
    )
  }

  func testAssignmentStatementWithLET() {
    checkStatement(
      "25 LET A = 2",
      .assign(
          .variable("A", .number),
          .number(2.0))
    )
  }

  func testAssignMissingEqualSign() {
    checkError(
      "42 HUH REMARK",
      .error("Assignment is missing '='")
    )
  }

  func testLETMissingAssignment() {
    checkError(
      "42 LET",
      ParseError.error("LET is missing variable to assign to")
    )
  }

  func testAssignStringToNumberFails() {
    checkError(
      "17 A=B$",
      .error("Type mismatch")
    )
  }

  func testStandaloneStringInExpression() {
    checkStatement(
      "25 A$ = \"body\"",
      .assign(
          .variable("A$", .string),
          .string("body"))
    )
  }

  func testPrintString() {
    checkStatement(
      "25 PRINT \"body\"",
      .print(
          [.string("body")])
    )
  }

  func testStringCantDoArithmetic() {
    checkError("17 A=-B$", .error("Numeric type is required"))

    checkError("17 A=B$^3", .error("Type mismatch"))
    checkError("17 A=3^B$", .error("Type mismatch"))

    checkError("17 A=B$*C$", .error("Type mismatch"))
    checkError("17 A=3/B$", .error("Type mismatch"))

    checkError("17 A=B$+C$", .error("Type mismatch"))
    checkError("17 A=3-B$", .error("Type mismatch"))

    checkError("17 A=NOT B$", .error("Numeric type is required"))
    checkError("17 A=B$ AND 3", .error("Type mismatch"))
    checkError("17 A=42 OR B$", .error("Type mismatch"))
  }

  func testRelationalOperatorNeedsSameTypes() {
    checkError("17 A=B$ < 3", .error("Type mismatch"))
    checkError("17 A=33=B$", .error("Type mismatch"))
  }

  func testDefDefinesHelperFunctions() {
    checkStatement(
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
    checkError("17 DEF F(X)=X", .error("DEF requires a name of the form FNx"))
    checkError("17 DEF FN(x)=X", .error("DEF requires a name of the form FNx"))
    checkError("17 DEF FNX9(x)=X", .error("DEF function name cannot be followed by extra letters"))
    checkError("17 DEF FNI x)=X", .error("Missing '('"))
    checkError("17 DEF FNZ()=X", .error("Variable is required"))
    checkError("17 DEF FNA(x=X", .error("DEF requires ')' after parameter"))
    checkError("17 DEF FNP(x) -> X", .error("DEF requires '=' after parameter definition"))
  }

  func testPredefinedFunction() {
    checkStatement(
      "25 PRINT SQR(4)",
      .print(
          [.predefined("SQR", [.number(4)], .number)]
        )
    )
  }

  func testPredefinedStringFunctionReturnType() {
    checkStatement(
      "25 PRINT CHR$(4)",
      .print(
          [.predefined("CHR$", [.number(4)], .string)]
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
      .error("Type mismatch")
    )
  }

  func testCantAssignPredefinedStringFunctionCallToNumericVariable() {
    checkError(
      "25 A=CHR$(17)",
      .error("Type mismatch")
    )
  }

  func testPredefinedFunctionEnforcesNumberOfArguments() {
    checkError(
      "25 PRINT LEFT$(\"X\")",
      .error("Type mismatch")
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
      .error("Type mismatch")
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
    checkStatement(
      "10 PRINT FNI(3)",
      .print([
          .userdefined(
            "FNI",
            .number(3) )
        ]))
  }

  func testDefCallMustTakeNumericArgument() {
    checkError(
      "10 PRINT FNI(\"str\")",
      .error("Type mismatch"))
  }

  func testUserDefinedFunctionsMustHaveNumericResult() {
    checkError("""
10 DEF FNA(Y)="string"
""",
               .error("Numeric type is required"))
  }

  func testDIMNumber() {
    checkStatement(
      "10 DIM A(5)",
      .dim("A", [6], .number)
    )
  }

  func testDIMString() {
    checkStatement(
      "10 DIM Z9$(5)",
      .dim("Z9$", [6], .string)
    )
  }

  func testMultiDimensionalDIM() {
    checkStatement(
      "10 DIM Z(3,4,5)",
      .dim("Z", [4,5,6], .number)
      )
  }

  func testRightParendErrorInDim() {
    checkError(
      "10 DIM Z(3",
      ParseError.error("Missing ')'"))
  }
  
  func testFetchFromArray() {
    checkStatement(
      "10 PRINT A(0)",
      .print([
          .arrayAccess("A", .number, [.number(0)])
        ])
    )
  }

  func testFetchFromMultiDArray() {
    checkStatement(
      "10 PRINT A(1,2)",
      .print([
          .arrayAccess("A", .number, [.number(1),
               .number(2)])
        ])
    )
  }

  func testFORwithoutSTEP() {
    checkStatement(
      "10 FOR X=1 TO 10",
      .`for`("X", .number(1), .number(10), .number(1))
    )
  }

  func testFORwithSTEP() {
    checkStatement(
      "10 FOR X=1 TO 10 STEP 5",
      .`for`("X", .number(1), .number(10), .number(5))
    )
  }

  func testFORrequiresVariableEqualsAndTO() {
    checkError(
      "10 FOR 1 TO 10",
      ParseError.error("Variable is required")
    )
    checkError(
      "10 FOR X (1) TO 10",
      ParseError.error("'=' is required")
    )
    checkError(
      "10 FOR X = 1, 10",
      ParseError.error("'TO' is required")
    )
  }

  func testFORrequiresNumericExpressions() {
    checkError(
      "10 FOR X=\"string\" TO 10",
      ParseError.error("Numeric type is required")
    )
    checkError(
      "10 FOR X=1 TO \"10\"",
      ParseError.error("Numeric type is required")
    )
    checkError(
      "10 FOR X = 1 TO 10 STEP \"X\"",
      ParseError.error("Numeric type is required")
    )
  }

  func testNEXTwithVariable() {
    checkStatement(
      "10 NEXT Z9",
      .next("Z9")
    )
  }

  func testNEXTrequiresVariable() {
    checkError(
      "10 NEXT",
      ParseError.error("Variable is required")
    )
  }

  func testGOSUB() {
    checkStatement(
      "10 GOSUB 20",
      .gosub(20))
  }

  func testGOSUBrequiresLineNumber() {
    checkError(
      "10 GOSUB",
      ParseError.error("Missing target of GOSUB"))

    checkError(
      "10 GOSUB X",
      ParseError.error("Missing target of GOSUB"))
  }

  func testRETURN() {
    checkStatement(
      "10 RETURN",
      .`return`)
  }

  func testRETURNstandsAlone() {
    checkError(
      "10 RETURN X",
      ParseError.error("Extra characters at end of line"))
  }

  func testON_GOTO() {
    checkStatement(
      "10 ON 2 GOTO 10,20,30",
      .onGoto(
        .number(2),
        [10, 20, 30]))
  }

  func testONmissingGOTOisError() {
    checkError(
      "10 ON 2 THEN 10,20,30",
      ParseError.error("GOTO is missing"))
  }

  func testONmissingLineNumbersIsError() {
    checkError(
      "10 ON 2 GOTO X",
      ParseError.error("ON..GOTO requires at least one line number after GOTO"))
  }
}

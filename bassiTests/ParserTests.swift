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
    _ = parser.parse(line)
    XCTAssertEqual(
      parser.errors(),
      [expected])
  }

  func checkParsing(
    _ program: String,
    _ expected: Parse)
  {
    let parser = Parser()
    let result = parser.parse(program)
    XCTAssertEqual(
      result,
      expected
    )
    XCTAssertEqual(parser.errorMessages, [])
  }

  func checkExpression(
    _ expression: String,
    _ expected: Expression) {

      let input = "10 PRINT \(expression)"
      let parser = Parser()
      let result = parser.parse(input)
      XCTAssertEqual(
        result,
        .line(
          10,
          .print([expected]))
      )
      XCTAssertEqual(parser.errorMessages, [])
    }

  func checkRelational(_ relation: String, _ token: Token) throws {
    checkExpression(
      "1" + relation + "2",
      Expression.make(1, token, 2)
    )
  }

  func test10END() throws {
    checkParsing(
      "1 END",
      .line(1, .end))
    checkParsing(
      "99999 END",
      .line(99999, .end))
  }

  func testLineNumberIsInRange0to99999() {
    checkError(
      "0 END", ParseError.lineNumberRange)

    checkError(
      "100000 END", ParseError.lineNumberRange)
  }

  func test10REM() throws {
    checkParsing(
      "10 REM whatever",
      .line(10, .skip)
    )
  }

  func testNoLineNumber() {
    checkError(
      "REM remark",
      .noLineNumber)
  }

  func testPrintStatement() {
    checkParsing(
      "25 PRINT",
      .line(25, .print([]))
    )
  }

  func testPrintStatementWithNumber() {
    checkParsing(
      "25 PRINT 42",
      .line(
        25,
        .print([.number(42.0)]))
    )
  }

  func testPrintPrintIsError() {
    checkError(
      "25 PRINT PRINT",
      .expectedStartOfExpression
    )
  }

  func testGoto() throws {
    checkParsing(
      "10 GOTO 10",
      .line(
        10,
        .goto(10))
    )
  }

  func testGotoWithMissingTarget() throws {
    checkError(
      "10 GOTO",
      .missingTarget
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
      .missingRightParend
    )
  }

  func testPrintImproperExpression() {
    checkError(
      "10 PRINT +",
      .expectedStartOfExpression
    )
  }
  func testErrorWhenFactorIsNotValid() {
    let expression = "(((*"
    checkError(
      "10 PRINT \(expression)",
      .expectedStartOfExpression
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
    checkParsing(
      "42 IF 0 THEN 43",
      .line(
        42,
        .`if`(.number(0), 43))
    )
  }

  func testIfMustCheckNumericType() throws {
    checkError(
      "42 IF A$ THEN 43",
      .floatRequired)
  }

  func testIfMissingThenGetsError() throws {
    checkError(
      "42 IF 0 PRINT",
      .missingTHEN
    )
  }

  func testIfThenMissingTargetGetsError() throws {
    checkError(
      "42 IF 0 THEN",
      .missingTarget
    )
  }

  func testAssignmentStatementWithNumber() {
    checkParsing(
      "25 X = 42",
      .line(
        25,
        .assign(
          .variable("X", .number),
          .number(42.0)))
    )
  }

  func testAssignmentStatementWithLET() {
    checkParsing(
      "25 LET A = 2",
      .line(
        25,
        .assign(
          .variable("A", .number),
          .number(2.0)))
    )
  }

  func testAssignMissingEqualSign() {
    checkError(
      "42 HUH REMARK",
      .assignmentMissingEqualSign
    )
  }

  func testLETMissingAssignment() {
    checkError(
      "42 LET",
      ParseError.letMissingAssignment
    )
  }

  func testAssignStringToNumberFails() {
    checkError(
      "17 A=B$",
      .typeMismatch
    )
  }

  func testStandaloneStringInExpression() {
    checkParsing(
      "25 A$ = \"body\"",
      .line(
        25,
        .assign(
          .variable("A$", .string),
          .string("body")))
    )
  }

  func testPrintString() {
    checkParsing(
      "25 PRINT \"body\"",
      .line(
        25,
        .print(
          [.string("body")]))
    )
  }

  func testStringCantDoArithmetic() {
    checkError("17 A=-B$", .floatRequired)

    checkError("17 A=B$^3", .typeMismatch)
    checkError("17 A=3^B$", .typeMismatch)

    checkError("17 A=B$*C$", .typeMismatch)
    checkError("17 A=3/B$", .typeMismatch)

    checkError("17 A=B$+C$", .typeMismatch)
    checkError("17 A=3-B$", .typeMismatch)

    checkError("17 A=NOT B$", .floatRequired)
    checkError("17 A=B$ AND 3", .typeMismatch)
    checkError("17 A=42 OR B$", .typeMismatch)
  }

  func testRelationalOperatorNeedsSameTypes() {
    checkError("17 A=B$ < 3", .typeMismatch)
    checkError("17 A=33=B$", .typeMismatch)
  }

  func testDefDefinesHelperFunctions() {
    checkParsing(
      "25 DEF FNI(x)=x",
      .line(
        25,
        .def(
          "FNI",
          "X",
          .variable("X", .number),
          .function([.number], .number)
        )
      )
    )
  }

  func testDefErrorMessages() {
    checkError("17 DEF F(X)=X", .DEFfunctionMustStartWithFn)
    checkError("17 DEF FN(x)=X", .DEFrequiresVariableAfterFn)
    checkError("17 DEF FNX9(x)=X", .DEFfunctionNameMustBeFnFollowedBySingleLetter)
    checkError("17 DEF FNI x)=X", .missingLeftParend)
    checkError("17 DEF FNZ()=X", .FNrequiresParameterVariable)
    checkError("17 DEF FNA(x=X", .DEFrequiresRightParendAfterParameter)
    checkError("17 DEF FNP(x) -> X", .DEFrequiresEqualAfterParameter)
  }

  func testPredefinedFunction() {
    checkParsing(
      "25 PRINT SQR(4)",
      .line(
        25,
        .print(
          [.predefined("SQR", .number(4), .number)]
        )
      )
    )
  }

  func testPredefinedStringFunctionReturnType() {
    checkParsing(
      "25 PRINT CHR$(4)",
      .line(
        25,
        .print(
          [.predefined("CHR$", .number(4), .string)]
        )
      )
    )
  }

  func testChrParsesString() {
    checkExpression(
      "ASC(\"\")",
      .predefined(
        "ASC",
        .string(""),
        .number)
    )
  }
  
  func testPredefinedFunctionEnforcesTypes() {
    checkError(
      "25 PRINT SQR(\"X\")",
      .typeMismatch
    )
  }

  func testCantAssignPredefinedStringFunctionCallToNumericVariable() {
    checkError(
      "25 A=CHR$(17)",
      .typeMismatch
    )
  }

  func testPredefinedFunctionEnforcesNumberOfArguments() {
    checkError(
      "25 PRINT LEFT$(\"X\")",
      .argumentCountMismatch
    )
  }


  func testDefCall() {
    checkParsing(
      "10 PRINT FNI(3)",
      .line(
        10,
        .print([
          .userdefined(
            "FNI",
            .number(3) )
        ])))
  }

  func testDefCallMustTakeNumericArgument() {
    checkError(
      "10 PRINT FNI(\"str\")",
      .typeMismatch)
  }

  func testUserDefinedFunctionsMustHaveNumericResult() {
    checkError("""
10 DEF FNA(Y)="string"
""",
       .floatRequired)
  }
}

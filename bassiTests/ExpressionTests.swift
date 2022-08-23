//
//  ExpressionTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/25/22.
//

import XCTest
@testable import bassi

class ExpressionTests: XCTestCase {
  func checkExpression(
    _ expression: String,
    _ expected: Expression) {

      let input = "10 PRINT \(expression)"
      let parser = SyntaxAnalyzer()
      let result = parser.parse(input)
      XCTAssertEqual(
        result,
        Parse(
          10,
          [.print([.expr(expected), .newline])])
      )
    }

  func checkError(
    _ program: String,
    _ expected: String)
  {
    let line = program
    let parser = SyntaxAnalyzer()
    let output = parser.parse(line)

    if case .error(_, _, let actualMessage) = output.statements[0] {
      XCTAssertEqual(
        actualMessage,
        expected)
      return
    }

    XCTFail("no error found")
  }

  func checkOneStatement(
    _ program: String,
    _ expected: Statement)
  {
    let parser = SyntaxAnalyzer()
    let result = parser.parse(program)
    XCTAssertEqual(
      result.statements,
      [expected]
    )
  }

  func testNumberHasTypeFloat() {
    let number = Expression.number(37.5)
    XCTAssertEqual(number.type(), .number)
  }

  func testVariableHasSpecifiedType() {
    XCTAssertEqual(Expression.variable("X", .number).type(), .number)
    XCTAssertEqual(Expression.variable("Y", .string).type(), .string)
  }

  func testOperatorsAllHaveTypeFloat() {
    XCTAssertEqual(
      Expression.op1(.minus, .number(3)).type(),
      .number)
    XCTAssertEqual(
      Expression.op2(.plus,
          .number(1),
          .number(2)).type(),
      .number)
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

  func testCallOfPredefinedFunctionHasProperReturnType() {
    let call = Expression.predefined("CHR$", [.number(3)], .string)
    XCTAssertEqual(call.type(), .string)
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
          .number(3) )),
        .newline
      ]))
  }

  func testFetchFromArray() {
    checkOneStatement(
      "10 PRINT A(0)",
      .print([
        .expr(.arrayAccess("A", .number, [.number(0)])),
        .newline
      ])
    )
  }

  func testFetchFromMultiDArray() {
    checkOneStatement(
      "10 PRINT A(1,2)",
      .print([
        .expr(.arrayAccess("A", .number, [.number(1),
                                          .number(2)])),
        .newline
      ])
    )
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

  func testPredefinedFunction() {
    checkOneStatement(
      "25 PRINT SQR(4)",
      .print(
        [.expr(.predefined("SQR", [.number(4)], .number)), .newline]
      )
    )
  }

  func testPredefinedFunctionMissingLeftParend() {
    checkError("17 PRINT SQR 4)", "Expected '('")
  }

  func testPredefinedStringFunctionReturnType() {
    checkOneStatement(
      "25 PRINT CHR$(4)",
      .print(
        [.expr(.predefined("CHR$", [.number(4)], .string)), .newline]
      )
    )
  }
}

//
//  DimArrayTests.swift
//  bassiTests
//
//  Created by Bill Wake on 7/4/22.
//

import XCTest
@testable import bassi

class DimArrayTests: InterpreterTests {
  func testArrayValuesEqualIfDimensionsAndContentsAreEqual() {
    XCTAssertEqual(
      Value.array(
        BasicArray([3], [.number(0), .number(0), .number(0)], .number)),
      Value.array(
        BasicArray([3], [.number(0), .number(0), .number(0)], .number))
    )
  }

  func testDIMknowsTypeAndSize() throws {
    let program = Program("10 DIM A(2)")
    let outputter = Interactor()
    let interpreter = Interpreter(program, outputter)
    let _ = try interpreter.run()
    XCTAssertEqual(
      interpreter.globals["A"]!,
      .array(
        BasicArray([3],
                   [.number(0), .number(0), .number(0)],
                   .number)))
  }

  func testDIMknowsTypeAndSizeForMultipleArrays() throws {
    let program = Program("10 DIM A(2), B(1)")
    let outputter = Interactor()
    let interpreter = Interpreter(program, outputter)
    let _ = try interpreter.run()
    XCTAssertEqual(
      interpreter.globals["A"]!,
      .array(
        BasicArray([3],
                   [.number(0), .number(0), .number(0)],
                   .number)))
    XCTAssertEqual(
      interpreter.globals["B"]!,
      .array(
        BasicArray([2],
                   [.number(0), .number(0)],
                   .number)))
  }

  func testDIMknowsTypeAndSizeForMultiDArray() throws {
    let program = Program("10 DIM A(2,1,2)")
    let outputter = Interactor()
    let interpreter = Interpreter(program, outputter)
    let _ = try interpreter.run()

    XCTAssertEqual(
      interpreter.globals["A"]!,
      .array(
        BasicArray([3,2,3],
                   Array<Value>(repeating: .number(0.0), count: 3*2*3),
                   .number)))
  }

  func testDIMmayNotRedeclareVariables() throws {
    do {
      let program = Program("10 DIM A(2)")
      let outputter = Interactor()
      let interpreter = Interpreter(program, outputter)
      interpreter.globals["A"] = .number(27)
      let _ = try interpreter.run()
    } catch InterpreterError.error(_, let message) {
      XCTAssertEqual(message, "Can't redeclare array A")
    }
  }

  func testArrayAccess() {
    checkProgramResults(
      "10 DIM A(3)\n20 PRINT A(0)",
      expecting: " 0 \n")
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
                        expecting: " 17 \n 42 \n")
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
    let outputter = Interactor()
    let interpreter = Interpreter(program, outputter)
    let _ = try interpreter.run()

    var expected = Array<Value>(
      repeating: .number(0),
      count: 11)
    expected[2] = .number(3)

    XCTAssertEqual(
      interpreter.globals["A"]!,
      .array(BasicArray([11], expected, .number))
    )
  }

  func testArrayAccessWithoutDIMdefaultsToSize10() throws {
    let program = Program("10 PRINT A(2)")
    let outputter = Interactor()
    let interpreter = Interpreter(program, outputter)
    let _ = try interpreter.run()

    let values = Array<Value>(repeating: .number(0), count: 11)

    XCTAssertEqual(
      interpreter.globals["A"]!,
      .array(BasicArray([11], values, .number))
    )
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
                        expecting: " 12 \n 11 \n"
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
expecting: " 1 \n 2 \n 3 \n 4 \n 5 \n 6 \n 7 \n 8 \n 9 \n 10 \n 11 \n 12 \n 13 \n 14 \n 15 \n")
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

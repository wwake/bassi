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

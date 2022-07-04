//
//  DefTests.swift
//  bassiTests
//
//  Created by Bill Wake on 7/4/22.
//

import XCTest
@testable import bassi

class DefTests: InterpreterTests {
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
}

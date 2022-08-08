//
//  _ControlFlowTests.swift
//  bassiTests
//
//  Created by Bill Wake on 7/4/22.
//

import Foundation


import XCTest
@testable import bassi

class _ControlFlowTests: InterpreterTests {
  func testGatherDataWhenStatementHasError() throws {
    let program = "10 PRINT {}"
    let outputter = Interactor()
    let interpreter = Interpreter(Program(program), outputter)
    try interpreter.gatherData()
    XCTAssertEqual([], interpreter.data)
  }

  func testSyntaxErrorStopsInterpreter() throws {
    let program = "10 PRINT {}"
    let outputter = Interactor()
    let interpreter = Interpreter(Program(program), outputter)
    try interpreter.run()
    XCTAssertTrue(outputter.output.starts(with:"?10:7 Expected start of expression"), "was \(outputter.output)")
  }

  func testRemainingPartsOfLineDontExecuteIfControlTransfered() {
    checkProgramResults(
"""
10 GOTO 20: PRINT 10
20 PRINT 20
""", expecting: " 20 \n")
  }

  func test10Goto10() throws {
    let parse =
    Parse(
      10,
      [.goto(10)])

    let outputter = Interactor()
    let interpreter = Interpreter(Program("10 GOTO 10"), outputter)

    XCTAssertEqual(interpreter.nextLocation, nil)

    let _ = try interpreter.step(parse.statements[0])

    XCTAssertEqual(interpreter.nextLocation, Location(10,0))
  }

  func testStepWillTryToGotoMissingLine() throws {
    let parse =
    Parse(
      10,
      [.goto(20)])

    let outputter = Interactor()
    let interpreter = Interpreter(Program(), outputter)

    let _ = try interpreter.step(parse.statements[0])

    XCTAssertEqual(interpreter.nextLocation, Location(20,0))
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
                        expecting: " 25 \n")
  }

  func testRunMultiLineProgramAndFallOffTheEnd() throws {
    checkProgramResults("""
25 GOTO 50
30 PRINT 30
50 PRINT 50
""",
                        expecting: " 50 \n")
  }
}

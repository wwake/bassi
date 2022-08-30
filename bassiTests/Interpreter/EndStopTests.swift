//
//  EndStopTests.swift
//  bassiTests
//
//  Created by Bill Wake on 7/4/22.
//

import XCTest
@testable import bassi

class EndStopTests: InterpreterTests {
  func testEnd() throws {
    let program = Program("999 END")
    let outputter = Interactor()
    let interpreter = Interpreter(program, outputter)
    let _ = try interpreter.run()
    XCTAssertTrue(interpreter.done)
  }

  func testEndThrowsErrorIfAnyActiveSubroutines() throws {
    let program =
"""
10 GOSUB 20
20 X=1
"""

    checkExpectedError(
      program,
      expecting: "Ended program without returning from active subroutine")
  }

  func testStop() throws {
    checkProgramResults(
"""
10 STOP
15 PRINT 15
20 END
""",
expecting: "")
    }
}

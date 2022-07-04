//
//  ForNextTests.swift
//  bassiTests
//
//  Created by Bill Wake on 7/4/22.
//

import XCTest
@testable import bassi

class ForNextTests : InterpreterTests {

  func testFORwithPositiveStep() {
    checkProgramResults(
"""
10 FOR X=1 TO 3
20 PRINT X
35 NEXT X
40 PRINT X
""",
expecting: " 1 \n 2 \n 3 \n 3 \n")
  }

  func testFORwithNegativeStep() {
    checkProgramResults(
"""
10 FOR X=3 TO 1 STEP -1
20 PRINT X
35 NEXT X
40 PRINT X
""",
expecting: " 3 \n 2 \n 1 \n 1 \n")
  }

  func testFORstartingOutOfRange_DoesntExecute_but_DoesAdjustVariable()
  {
    checkProgramResults(
"""
10 FOR X=4 TO 2
20 PRINT 999
35 NEXT X
40 PRINT X
""",
expecting: " 3 \n"
    )
  }

  func testFORtestsVarPlusStep()
  {
    checkProgramResults(
"""
10 FOR X=2 TO 2
20 PRINT 999
35 NEXT X
40 PRINT X
""",
expecting: " 999 \n 2 \n"
    )
  }

  func testFORwithoutNEXTreportsError() {
    checkExpectedError(
      "10 FOR A0=1 TO 3",
      expecting: "Found FOR without NEXT: A0")
  }

  func testNEXTwithoutFORreportsError() {
    checkExpectedError(
      "30 NEXT X",
      expecting: "Found NEXT without preceding FOR")
  }

  func testNEXTvariableMustMatchFORvariable() {
    checkExpectedError(
"""
10 FOR A=1 TO 2
30 NEXT Z
40 NEXT A
""",
expecting: "NEXT variable must match corresponding FOR")
  }

  func testFORandNEXTonSameLine() {
    checkProgramResults(
"""
10 FOR I=1 TO 2:PRINT I: NEXT I
20 PRINT 20
""",
expecting: " 1 \n 2 \n 20 \n")
  }

  func testFORandNEXTonDifferentLineWithMultipleParts() {
    checkProgramResults(
"""
10 FOR I=1 TO 2: REM
15 PRINT I: NEXT I
20 PRINT 20
""",
expecting: " 1 \n 2 \n 20 \n")
  }

}

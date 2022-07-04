//
//  GosubReturnTests.swift
//  bassiTests
//
//  Created by Bill Wake on 7/4/22.
//

import XCTest
@testable import bassi

class GosubReturnTests : InterpreterTests {
  func testGOSUB() {
    checkProgramResults(
"""
10 GOSUB 100
15 PRINT 52
20 END
100 PRINT 42
110 RETURN
""",
expecting: " 42 \n 52 \n")
  }

  func testGOSUBinSubroutine() {
    checkProgramResults(
"""
10 GOSUB 100
20 PRINT 20
30 END
50 PRINT 50
60 RETURN
100 PRINT 100
110 GOSUB 50
120 RETURN
""",
expecting: " 100 \n 50 \n 20 \n")
  }

  func testRETURNwithoutGOSUB() {
    checkExpectedError("10 RETURN", expecting: "RETURN called before GOSUB")
  }

  func testGOSUBreturningInsideLine() {
    checkProgramResults(
"""
10 GOSUB 100: PRINT 10
20 PRINT 20
30 END
100 PRINT 100
110 RETURN
""",
expecting: " 100 \n 10 \n 20 \n")
  }
}

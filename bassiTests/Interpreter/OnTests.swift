//
//  OnTests.swift
//  bassiTests
//
//  Created by Bill Wake on 7/4/22.
//

import XCTest
@testable import bassi

class OnTests : InterpreterTests {

  func testON_GOTO() {
    checkProgramResults(
"""
10 ON 2 GOTO 20, 30, 20
15 PRINT 15
20 PRINT 20
30 PRINT 30
""",
expecting: " 30 \n")
  }

  func testON_GOTOwithNegativeValueThrowsError() {
    checkExpectedError(
"""
10 ON -1 GOTO 20, 20
15 PRINT 15
16 END
20 PRINT 20
""",
expecting: "?ILLEGAL QUANTITY")
  }

  func testON_GOTOwith0GoesToNextLine() {
    checkProgramResults(
"""
10 ON 0 GOTO 20, 20
15 PRINT 15
16 END
20 PRINT 20
""",
expecting: " 15 \n")
  }

  func testON_GOTOwithTooLargeValueGoesToNextLine() {
    checkProgramResults(
"""
10 ON 3 GOTO 20, 20
15 PRINT 15
16 END
20 PRINT 20
""",
expecting: " 15 \n")
  }

  func testON_GOSUB() {
    checkProgramResults(
"""
10 ON 2 GOSUB 20, 30, 20
12 END
20 PRINT 20
30 PRINT 30
40 RETURN
""",
expecting: " 30 \n")
  }

  func testON_GOSUBwithNegativeValueThrowsError() {
    checkExpectedError(
"""
10 ON -1 GOSUB 20, 20
15 PRINT 15
16 END
20 PRINT 20
""",
expecting: "?ILLEGAL QUANTITY")
  }

  func testON_GOSUBwith0GoesToNextLine() {
    checkProgramResults(
"""
10 ON 0 GOSUB 20, 20
15 PRINT 15
16 END
20 PRINT 20
25 RETURN
""",
expecting: " 15 \n")
  }

  func testON_GOSUBwithTooLargeValueGoesToNextLine() {
    checkProgramResults(
"""
10 ON 3 GOSUB 20, 20
15 PRINT 15
16 END
20 PRINT 20
30 RETURN
""",
expecting: " 15 \n")
  }
}

//
//  RemarkTests.swift
//  bassiTests
//
//  Created by Bill Wake on 7/4/22.
//

import XCTest
@testable import bassi

class RemarkTests: InterpreterTests {
  func test10REM() throws {
    checkProgramResults(
      "10 REM Comment",
      expecting: "")
  }

  func testSkip() throws {
    checkProgramResults(
"""
10 REM Skip this line
20 PRINT 20
""",
expecting: " 20 \n"
    )
  }


}


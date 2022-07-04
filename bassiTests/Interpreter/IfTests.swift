//
//  IfTests.swift
//  bassiTests
//
//  Created by Bill Wake on 7/4/22.
//

import XCTest
@testable import bassi

class IfTests: InterpreterTests {
  func ifWithFalseResultFallsThrough() throws {
    checkProgramResults("""
25 IF 0 THEN 50
30 PRINT 30
50 PRINT 50
""",
                        expecting: " 30 \n 50 \n")
  }

  func testIfWithTrueResultDoesGoto() throws {
    checkProgramResults("""
25 IF 1 THEN 50
30 PRINT 30
50 PRINT 50
""",
                        expecting: " 50 \n")
  }

  func testIfWithStatementRunsWhenTrue() throws {
    checkProgramResults("""
25 IF 1 THEN PRINT 25
50 PRINT 50
""",
                        expecting: " 25 \n 50 \n")
  }

  func testIfWithMultipleStatements() throws {
    checkProgramResults("""
25 IF 1 THEN PRINT 25: PRINT 30
50 PRINT 50
""",
                        expecting: " 25 \n 30 \n 50 \n")
  }

  func testIfWithMultipleStatementsAndFailingCondition() throws {
    checkProgramResults("""
25 IF 0 THEN PRINT 25: PRINT 30
50 PRINT 50
""",
                        expecting: " 50 \n")
  }

}

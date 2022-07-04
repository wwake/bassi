//
//  StopResumeTests.swift
//  bassiTests
//
//  Created by Bill Wake on 7/4/22.
//

import XCTest
@testable import bassi

class StopResumeTests: InterpreterTests {
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

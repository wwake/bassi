//
//  DataReadTests.swift
//  bassiTests
//
//  Created by Bill Wake on 7/5/22.
//

import XCTest
@testable import bassi

class DataReadTests: InterpreterTests {
  func testReadMultipleStrings() {
    checkProgramResults(
      "10 DATA DOG, CAT\n20 READ X$, Y$\n30 PRINT X$,Y$",
      expecting: "DOG         CAT\n")
  }

  func testReadMultipleStringsFromSeparateDATAstatementsAnywhereInProgram() {
    checkProgramResults(
      "10 DATA DOG\n20 READ X$,Y$\n25 DATA CAT\n30 PRINT X$,Y$",
      expecting: "DOG         CAT\n")
  }

  func testReadDataAnywhereInLine() {
    checkProgramResults(
      "10 READ X$,Y$:DATA DOG\n25 DATA CAT\n30 PRINT X$,Y$",
      expecting: "DOG         CAT\n")
  }


}

//
//  REPLTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/13/22.
//

import XCTest
@testable import bassi

class ProgramTests: XCTestCase {

  func testAddingLineSavesIt() {
    let program = Program()
    program[10] = "10 PRINT 42"
    XCTAssertEqual(program[10], "10 PRINT 42")
  }
  
    func testAddingSameLineNumberOverwrites() throws {
      let program = Program()
      program[10] = "10 PRINT 42"
      program[10] = "10 PRINT 43"
      XCTAssertEqual(program[10], "10 PRINT 43")
    }

  func testNonExistentLinesAreEmpty() {
    let program = Program()
    XCTAssertEqual(program[20], "")
  }

  func testJustLineNumberErasesEntry() {
    let program = Program()
    program[25] = "25 PRINT"
    program[25] = "25"
    XCTAssertEqual(program[25], "")
  }
}

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

  func testProgramKnowsItsFirstLineNumber() {
    let program = Program()
    program[25] = "25 PRINT"
    program[40] = "40 PRINT"
    XCTAssertEqual(25, program.firstLineNumber())
  }

  func testEmptyProgramSaysFirstLineNumberIsZero() {
    let program = Program()
    XCTAssertEqual(0, program.firstLineNumber())
  }

  func testInitializeMultiLineProgram() {
    let program = Program("""
25 PRINT 25
40 END
""")
    XCTAssertEqual(program[25], "25 PRINT 25")
    XCTAssertEqual(program[40], "40 END")
  }

  func testUnknownNextLineNumberIsZeroEnd() {
    let program = Program()
    XCTAssertEqual(program.lineAfter(10), nil)
  }

  func testLineAfterOnlyLineIsZeroEnd() {
    let program = Program("""
10 PRINT 10
""")
    XCTAssertEqual(program.lineAfter(10), nil)
  }

  func testLineAfterFirstLineIsSecondLine() {
    let program = Program("""
10 PRINT 10
20 PRINT 20
""")
    XCTAssertEqual(program.lineAfter(10), 20)
  }
}

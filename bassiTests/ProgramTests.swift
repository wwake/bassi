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

  func testNonExistentLinesAreNil() {
    let program = Program()
    XCTAssertNil(program[20])
  }

  func testJustLineNumberErasesEntry() {
    let program = Program()
    program[25] = "25 PRINT"
    program[25] = "25"
    XCTAssertEqual(program[25], nil)
  }

  func testProgramKnowsItsFirstLineNumber() {
    let program = Program()
    program[25] = "25 PRINT"
    program[40] = "40 PRINT"
    XCTAssertEqual(25, program.firstLineNumber())
  }

  func testEmptyProgramSaysFirstLineNumberIsMaxLineNumber() {
    let program = Program()
    XCTAssertEqual(
      program.firstLineNumber(),
      program.maxLineNumber)
  }

  func testInitializeMultiLineProgram() {
    let program = Program("""
25 PRINT 25
40 END
""")
    XCTAssertEqual(program[25], "25 PRINT 25")
    XCTAssertEqual(program[40], "40 END")
  }

  func testUnknownNextLineNumberIsMaxLineNumber() {
    let program = Program()
    XCTAssertEqual(program.lineAfter(10), program.maxLineNumber)
  }

  func testLineAfterOnlyLineIsMaxLineNumber() {
    let program = Program("""
10 PRINT 10
""")
    XCTAssertEqual(program.lineAfter(10), program.maxLineNumber)
  }

  func testLineAfterFirstLineIsSecondLine() {
    let program = Program("""
10 PRINT 10
20 PRINT 20
""")
    XCTAssertEqual(program.lineAfter(10), 20)
  }
}

//
//  REPLTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/13/22.
//
import XCTest
@testable import bassi

class ReplTests: XCTestCase {

  func testCommandGetsEchoed() {
    let output = Output()
    let repl = Repl(output)
    repl.execute("10 PRINT")
    XCTAssertTrue(output.output.contains("10 PRINT\n"))
  }

  func testAddingLineSavesIt() {
    let output = Output()
    let repl = Repl(output)
    repl.execute("10 PRINT 42")

    XCTAssertTrue(repl.contains(10))
    XCTAssertFalse(repl.contains(20))
  }

  func testMultiLineCommandExecutesEachOne() {
    let output = Output()
    let repl = Repl(output)
    repl.execute("10 PRINT 10\n20 PRINT 20")

    XCTAssertEqual(repl[10], "10 PRINT 10")
    XCTAssertEqual(repl[20], "20 PRINT 20")
  }

  func testListKnowsProgram() {
    let output = Output()
    let repl = Repl(output)

    repl.execute("10 PRINT 42")
    repl.execute("LisT")

    XCTAssertEqual(
      output.output,
"""
10 PRINT 42
LisT
10 PRINT 42

""")
  }

  func testListSortsByLineNumber() {
    let output = Output()
    let repl = Repl(output)

    repl.execute("10 PRINT 42")
    repl.execute("20 PRINT 22")
    repl.execute("5 PRINT 5")
    repl.execute("LIST")

    XCTAssertEqual(
      output.output,
"""
10 PRINT 42
20 PRINT 22
5 PRINT 5
LIST
5 PRINT 5
10 PRINT 42
20 PRINT 22

""")
  }

  func testReplRun() {
    let output = Output()
    let repl = Repl(output)

    repl.execute("10 PRINT 42")

    repl.execute("run")

    let expected = """
10 PRINT 42
run
 42 

"""

    XCTAssertEqual(output.output.count, expected.count)
    XCTAssertEqual(output.output, expected)
  }
}

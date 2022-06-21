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
    let repl = Repl()
    let output = Output()
    repl.execute("10 PRINT", output)
    XCTAssertTrue(output.output.contains("10 PRINT\n"))
  }

  func testAddingLineSavesIt() {
    let repl = Repl()
    let output = Output()
    repl.execute("10 PRINT 42", output)

    XCTAssertTrue(repl.contains(10))
    XCTAssertFalse(repl.contains(20))
  }

  func testListKnowsProgram() {
    let repl = Repl()
    let output = Output()

    repl.execute("10 PRINT 42", output)
    repl.execute("LisT", output)

    XCTAssertEqual(
      output.output,
"""
10 PRINT 42
LisT
10 PRINT 42

""")
  }

  func testListSortsByLineNumber() {
    let repl = Repl()
    let output = Output()

    repl.execute("10 PRINT 42", output)
    repl.execute("20 PRINT 22", output)
    repl.execute("5 PRINT 5", output)
    repl.execute("LIST", output)

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
    let repl = Repl()
    let output = Output()

    repl.execute("10 PRINT 42", output)

    repl.execute("run", output)

    let expected = """
10 PRINT 42
run
42

"""

    XCTAssertEqual(output.output.count, expected.count)
    XCTAssertEqual(output.output, expected)
  }
}

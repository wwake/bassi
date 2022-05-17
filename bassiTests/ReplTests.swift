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
    repl.execute("10 PRINT")
    XCTAssertTrue(repl.output.contains("10 PRINT\n"))
  }

  func testAddingLineSavesIt() {
    let repl = Repl()
    repl.execute("10 PRINT 42")

    XCTAssertTrue(repl.contains(10))
    XCTAssertFalse(repl.contains(20))
  }

  func testListKnowsProgram() {
    let repl = Repl()
    repl.execute("10 PRINT 42")
    repl.execute("LisT")

    XCTAssertEqual(
      repl.output,
"""
HELLO
10 PRINT 42
LisT
10 PRINT 42

""")
  }

  func testListSortsByLineNumber() {
    let repl = Repl()
    repl.execute("10 PRINT 42")
    repl.execute("20 PRINT 22")
    repl.execute("5 PRINT 5")
    repl.execute("LIST")

    XCTAssertEqual(
      repl.output,
"""
HELLO
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
    repl.execute("10 PRINT 42")

    repl.execute("run")

    let expected = """
HELLO
10 PRINT 42
run
42

"""

    print("*\(repl.output[0])*")
    XCTAssertEqual(repl.output.count, expected.count)
    XCTAssertEqual(repl.output, expected)

  }
}

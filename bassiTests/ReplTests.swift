//
//  REPLTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/13/22.
//
import XCTest
@testable import bassi

class ReplTests: XCTestCase {
  func makeRepl() -> Repl {
    let program = Program()
    let output = Output()
    return Repl(program, output)
  }

  func testCommandGetsEchoed() {
    let repl = makeRepl()
    repl.execute("10 PRINT")
    XCTAssertTrue(repl.output.output.contains("10 PRINT\n"))
  }

  func testAddingLineSavesIt() {
    let repl = makeRepl()
    repl.execute("10 PRINT 42")

    XCTAssertTrue(repl.contains(10))
    XCTAssertFalse(repl.contains(20))
  }

  func testMultiLineCommandExecutesEachOne() {
    let repl = makeRepl()
    repl.execute("10 PRINT 10\n20 PRINT 20")

    XCTAssertEqual(repl[10], "10 PRINT 10")
    XCTAssertEqual(repl[20], "20 PRINT 20")
  }

  func testListKnowsProgram() {
    let repl = makeRepl()

    repl.execute("10 PRINT 42")
    repl.execute("LisT")

    XCTAssertEqual(
      repl.output.output,
"""
10 PRINT 42
LisT
10 PRINT 42

""")
  }

  func testListSortsByLineNumber() {
    let repl = makeRepl()

    repl.execute("10 PRINT 42")
    repl.execute("20 PRINT 22")
    repl.execute("5 PRINT 5")
    repl.execute("LIST")

    XCTAssertEqual(
      repl.output.output,
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
    let repl = makeRepl()

    repl.execute("10 PRINT 42")

    repl.execute("run")

    let expected = """
10 PRINT 42
run
 42 

"""

    XCTAssertEqual(repl.output.output, expected)
  }
}

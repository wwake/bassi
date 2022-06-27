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

  func testReplRun() {
    let repl = makeRepl()

    repl.execute("10 PRINT 42")

    repl.doRun()

    let expected = """
10 PRINT 42
 42 

"""

    XCTAssertEqual(repl.output.output, expected)
  }
}

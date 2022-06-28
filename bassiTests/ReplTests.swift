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

  func testAddingLineSavesIt() {
    let repl = makeRepl()
    repl.execute("10 PRINT 42")

    XCTAssertEqual(repl[10], "10 PRINT 42")
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

    XCTAssertEqual(repl.output.output, " 42 \n")
  }

  func testContinueAfterStop() {
    let repl = makeRepl()
    repl.execute("10 STOP\n20 PRINT 20;\n30 PRINT 30")

    repl.doRun()
    XCTAssertTrue(repl.output.output.isEmpty)

    repl.doContinue()
    XCTAssertEqual(repl.output.output, " 20  30 \n")
  }

  func testReplKnowsVariablesAfterRun() {
    let repl = makeRepl()
    repl.execute("10 X=12")
    repl.doRun()

    XCTAssertEqual(repl.store["X"], Value.number(12))
  }
}
